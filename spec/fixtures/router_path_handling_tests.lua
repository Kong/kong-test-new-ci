local utils = require "kong.tools.utils"

-- The following tests are used by unit and integration tests
-- to test the router path handling. Putting them here avoids
-- copy-pasting them in several places.
--
-- The tests can obtain this table by requiring
-- "spec.fixtures.router_path_handling_tests"
--
-- The rows are sorted by service_path, route_path, strip_path, path_handling and request_path.
--
-- Notes:
-- * The tests are parsed into a hash form at the end
--   of this file before they are returned.
-- * Before a test can be executed, it needs to be "expanded".
--   For example, a test with {"v0", "v1"} must be converted
--   into two tests, one with "v0" and one with "v1". Each line
--   can be expanded using the `line:expand()` method.

local tests = {
  -- service_path    route_path  strip_path     request_path     expected_path
  {  "/",            "/",        {false, true}, "/",             "/",                  },
  {  "/",            "/",        {false, true}, "/route",        "/route",             },
  {  "/",            "/",        {false, true}, "/route/",       "/route/",            },
  {  "/",            "/",        {false, true}, "/routereq",     "/routereq",          },
  {  "/",            "/",        {false, true}, "/route/req",    "/route/req",         },
  -- 5
  {  "/",            "/route",   false,         "/route",        "/route",             },
  {  "/",            "/route",   false,         "/route/",       "/route/",            },
  {  "/",            "/route",   false,         "/routereq",     "/routereq",          },
  {  "/",            "/route",   true,          "/route",        "/",                  },
  {  "/",            "/route",   true,          "/route/",       "/",                  },
  {  "/",            "/route",   true,          "/routereq",     "/req",               },
  -- 11
  {  "/",            "/route/",  false,         "/route/",       "/route/",            },
  {  "/",            "/route/",  false,         "/route/req",    "/route/req",         },
  {  "/",            "/route/",  true,          "/route/",       "/",                  },
  {  "/",            "/route/",  true,          "/route/req",    "/req",               },
  -- 15
  {  "/srv",         "/rou",     false,         "/roureq",       "/srv/roureq",        },
  {  "/srv",         "/rou",     true,          "/roureq",       "/srv/req",           },
  -- 19
  {  "/srv/",        "/rou",     false,         "/rou",          "/srv/rou",           },
  {  "/srv/",        "/rou",     true,          "/rou",          "/srv",               },
  -- 22
  {  "/service",     "/",        {false, true}, "/",             "/service",           },
  {  "/service",     "/",        {false, true}, "/route",        "/service/route",     },
  {  "/service",     "/",        {false, true}, "/route/",       "/service/route/",    },
  -- 27
  {  "/service",     "/",        {false, true}, "/routereq",     "/service/routereq",  },
  {  "/service",     "/",        {false, true}, "/route/req",    "/service/route/req", },
  -- 31
  {  "/service",     "/route",   false,         "/route",        "/service/route",     },
  {  "/service",     "/route",   false,         "/route/",       "/service/route/",    },
  {  "/service",     "/route",   false,         "/routereq",     "/service/routereq",  },
  {  "/service",     "/route",   true,          "/route",        "/service",           },
  {  "/service",     "/route",   true,          "/route/",       "/service/",          },
  {  "/service",     "/route",   true,          "/routereq",     "/service/req",       },
  -- 41
  {  "/service",     "/route/",  false,         "/route/",       "/service/route/",    },
  {  "/service",     "/route/",  false,         "/route/req",    "/service/route/req", },
  {  "/service",     "/route/",  true,          "/route/",       "/service/",          },
  {  "/service",     "/route/",  true,          "/route/req",    "/service/req",       },
  -- 49
  {  "/service/",    "/",        {false, true}, "/route/",       "/service/route/",    },
  {  "/service/",    "/",        {false, true}, "/",             "/service/",          },
  {  "/service/",    "/",        {false, true}, "/route",        "/service/route",     },
  {  "/service/",    "/",        {false, true}, "/routereq",     "/service/routereq",  },
  {  "/service/",    "/",        {false, true}, "/route/req",    "/service/route/req", },
  -- 55
  {  "/service/",    "/route",   false,         "/route",        "/service/route",      },
  {  "/service/",    "/route",   false,         "/route/",       "/service/route/",     },
  {  "/service/",    "/route",   false,         "/routereq",     "/service/routereq",   },
  {  "/service/",    "/route",   true,          "/route",        "/service",            },
  {  "/service/",    "/route",   true,          "/route/",       "/service/",           },
  {  "/service/",    "/route",   true,          "/routereq",     "/service/req",        },
  -- 62
  {  "/service/",    "/route/",  false,         "/route/",       "/service/route/",     },
  {  "/service/",    "/route/",  false,         "/route/req",    "/service/route/req",  },
  {  "/service/",    "/route/",  true,          "/route/",       "/service/",           },
  {  "/service/",    "/route/",  true,          "/route/req",    "/service/req",        },
  -- 66
  -- The following cases match on host (not path
  {  "/",            nil,        {false, true}, "/",             "/",                  },
  {  "/",            nil,        {false, true}, "/route",        "/route",             },
  {  "/",            nil,        {false, true}, "/route/",       "/route/",            },
  -- 69
  {  "/service",     nil,        {false, true}, "/",             "/service",           },
  {  "/service",     nil,        {false, true}, "/route",        "/service/route",     },
  {  "/service",     nil,        {false, true}, "/route/",       "/service/route/",    },
  -- 74
  {  "/service/",    nil,        {false, true}, "/",             "/service/",          },
  {  "/service/",    nil,        {false, true}, "/route",        "/service/route",     },
  {  "/service/",    nil,        {false, true}, "/route/",       "/service/route/",    },
}


local function expand(root_test)
  local expanded_tests = { root_test }

  for _, field_name in ipairs({ "strip_path" }) do
    local new_tests = {}
    for _, test in ipairs(expanded_tests) do
      if type(test[field_name]) == "table" then
        for _, field_value in ipairs(test[field_name]) do
          local et = utils.deep_copy(test)
          et[field_name] = field_value
          new_tests[#new_tests + 1] = et
        end

      else
        new_tests[#new_tests + 1] = test
      end
    end
    expanded_tests = new_tests
  end

  return expanded_tests
end


local tests_mt = {
  __index = {
    expand = expand
  }
}


local parsed_tests = {}
for i = 1, #tests do
  local test = tests[i]
  parsed_tests[i] = setmetatable({
    service_path  = test[1],
    route_path    = test[2],
    strip_path    = test[3],
    request_path  = test[4],
    expected_path = test[5],
  }, tests_mt)
end

return parsed_tests
