local JSON = require 'ood.json'

--[[
  logger

  Hooks into the final logging stage to parse the response headers before
  outputting to the logs.
--]]
function logger(r)
  -- read in variables set previously in the request by mod_ood_proxy
  local user              = r.subprocess_env['MAPPED_USER'] -- set by the user mapping code
  local time_user_map     = r.subprocess_env['OOD_TIME_USER_MAP'] -- set by the user mapping code
  local time_begin_proxy  = r.subprocess_env['OOD_TIME_BEGIN_PROXY'] -- set by the proxy code

  -- only log authenticated users
  if user then
    local msg  = {}
    local time = r:clock()

    -- log
    msg["timestamp"] = os.date('!%Y-%m-%dT%T', time / 1000000) .. '.' .. time % 1000000 .. 'Z'
    msg["log_id"]    = r.log_id

    -- user
    msg["local_user"]  = user
    msg["remote_user"] = r.user

    -- session
    msg["user_ip"]       = r.useragent_ip
    msg["user_agent"]    = r.headers_in['User-Agent'] or ''
    msg["user_accept"]   = (r.headers_in['Accept'] or ''):lower()
    msg["user_encoding"] = (r.headers_in['Accept-Encoding'] or ''):lower()
    msg["user_lang"]     = (r.headers_in['Accept-Language'] or ''):lower()

    -- request
    msg["req_method"]    = r.method
    msg["req_status"]    = r.status
    msg["req_path"]      = r.uri
    msg["req_https"]     = r.is_https and 'true' or 'false'
    msg["req_host"]      = r.hostname
    msg["req_port"]      = r.port
    msg["req_server"]    = r.server_name
    msg["req_referer"]   = (r.headers_in['Referer'] or ''):match('^([^?]*)')

    -- response
    msg["res_encoding"]  = (r.headers_out['Content-Encoding'] or ''):lower()
    msg["res_length"]    = (r.headers_out['Content-Length'] or '')
    msg["res_type"]      = (r.headers_out['Content-Type'] or ''):lower()
    msg["res_disp"]      = (r.headers_out['Content-Disposition'] or '')

    -- benchmarks
    msg["time_proxy"]    = time_begin_proxy and (r:clock() - time_begin_proxy)/1000.0 or 0
    msg["time_user_map"] = time_user_map and tonumber(time_user_map) or 0

    r:info(JSON:encode(msg))
  end

  return apache2.DECLINED
end
