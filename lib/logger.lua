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
    local time = r:clock()

    -- log
    local timestamp = os.date('!%Y-%m-%dT%T', time / 1000000) .. '.' .. time % 1000000 .. 'Z'
    local log_id    = r.log_id

    -- user
    local local_user  = user
    local remote_user = r.user

    -- session
    local user_ip       = r.useragent_ip
    local user_agent    = r.headers_in['User-Agent'] or ''
    local user_accept   = (r.headers_in['Accept'] or ''):lower()
    local user_encoding = (r.headers_in['Accept-Encoding'] or ''):lower()
    local user_lang     = (r.headers_in['Accept-Language'] or ''):lower()

    -- request
    local req_method    = r.method
    local req_status    = tostring(r.status)
    local req_path      = r.uri
    local req_https     = r.is_https and 'true' or 'false'
    local req_host      = r.hostname
    local req_port      = tostring(r.port)
    local req_server    = r.server_name
    local req_referer   = (r.headers_in['Referer'] or ''):match('^([^?]*)')

    -- response
    local res_encoding  = (r.headers_out['Content-Encoding'] or ''):lower()
    local res_length    = (r.headers_out['Content-Length'] or '')
    local res_type      = (r.headers_out['Content-Type'] or ''):lower()
    local res_disp      = (r.headers_out['Content-Disposition'] or '')

    -- benchmarks
    local time_proxy    = tostring(time_begin_proxy and (r:clock() - time_begin_proxy)/1000.0 or 0)
    local time_user_map = tostring(time_user_map and time_user_map or 0)

    -- item to log
    local item =
      'timestamp="'      .. r:escape_logitem(timestamp)     .. '", ' ..
      ' log_id="'        .. r:escape_logitem(log_id)        .. '", ' ..
      ' local_user="'    .. r:escape_logitem(local_user)    .. '", ' ..
      ' remote_user="'   .. r:escape_logitem(remote_user)   .. '", ' ..
      ' user_ip="'       .. r:escape_logitem(user_ip)       .. '", ' ..
      ' user_agent="'    .. r:escape_logitem(user_agent)    .. '", ' ..
      ' user_accept="'   .. r:escape_logitem(user_accept)   .. '", ' ..
      ' user_encoding="' .. r:escape_logitem(user_encoding) .. '", ' ..
      ' user_lang="'     .. r:escape_logitem(user_lang)     .. '", ' ..
      ' req_method="'    .. r:escape_logitem(req_method)    .. '", ' ..
      ' req_status="'    .. r:escape_logitem(req_status)    .. '", ' ..
      ' req_path="'      .. r:escape_logitem(req_path)      .. '", ' ..
      ' req_https="'     .. r:escape_logitem(req_https)     .. '", ' ..
      ' req_host="'      .. r:escape_logitem(req_host)      .. '", ' ..
      ' req_port="'      .. r:escape_logitem(req_port)      .. '", ' ..
      ' req_server="'    .. r:escape_logitem(req_server)    .. '", ' ..
      ' req_referer="'   .. r:escape_logitem(req_referer)   .. '", ' ..
      ' res_encoding="'  .. r:escape_logitem(res_encoding)  .. '", ' ..
      ' res_length="'    .. r:escape_logitem(res_length)    .. '", ' ..
      ' res_type="'      .. r:escape_logitem(res_type)      .. '", ' ..
      ' res_disp="'      .. r:escape_logitem(res_disp)      .. '", ' ..
      ' time_proxy="'    .. r:escape_logitem(time_proxy)    .. '", ' ..
      ' time_user_map="' .. r:escape_logitem(time_user_map) .. '"'

    r:info(item)
  end

  return apache2.DECLINED
end
