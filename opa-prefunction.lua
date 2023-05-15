local cjson = require("cjson")
local http = require("resty.http")
local function do_request(table)
    local input = cjson.encode({input = table.body})
     kong.log.notice("Sending to OPA 2: "..input)
    local httpc = http.new()
    local ok, err = httpc:connect(table.host, table.port)
    local res, err = httpc:request({
        method = 'POST',
        path = table.path or '/',
        headers = table.headers or {},
        body = input
    })
    local body = res:read_body()
     kong.log.notice("OPA Response 2: "..body)
    return cjson.decode(body)
end
local auth = kong.request.get_header("Authorization")
local jwt = string.sub(auth, 8, #auth) -- Strip out "Bearer " prefix
local status, res = pcall(do_request, {
    ["host"] = 'opa.opa', -- Change to current OPA server
    ["port"] = 8181, -- Change to current OPA server port
    ["path"] = '/v1/data/rbac/allow',
    ["headers"] = {
        ["content-type"] = "application/json"
    },
    ["body"] = {
                ["action"] = kong.request.get_method(),
                ["context"] = { ["resourceId"] = kong.request.get_path() },
                ["jwt"] = jwt
            }
})
 kong.log.inspect(res)
if res then
    if not res.result then kong.response.exit(403) end
end