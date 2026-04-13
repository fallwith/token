-- Shared helpers for contrib generators.

local M = {}

function M.strip(hex)
  return hex:gsub('^#', '')
end

local function hex_to_rgb(hex)
  local h = M.strip(hex)
  return tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16), tonumber(h:sub(5, 6), 16)
end

function M.rgb_fmt(hex)
  local r, g, b = hex_to_rgb(hex)
  return string.format('0x%02x,0x%02x,0x%02x', r, g, b)
end

function M.sgr_rgb(hex)
  local r, g, b = hex_to_rgb(hex)
  return string.format('38;2;%d;%d;%d', r, g, b)
end

function M.sgr_bg_rgb(hex)
  local r, g, b = hex_to_rgb(hex)
  return string.format('48;2;%d;%d;%d', r, g, b)
end

function M.read_file(path)
  local f = io.open(path, 'r')
  if not f then
    return nil
  end
  local content = f:read('*a')
  f:close()
  return content
end

function M.mkdir_p(path)
  if path:find('[^A-Za-z0-9_./-]') then
    error('mkdir_p: refusing unsafe path: ' .. path)
  end
  os.execute('mkdir -p ' .. path)
end

function M.write_if_changed(path, content, verify)
  local existing = M.read_file(path)
  if existing == content then
    if not verify then
      io.write('skip: ' .. path .. ' (unchanged)\n')
    end
    return true
  end
  if verify then
    if existing == nil then
      io.stderr:write('missing: ' .. path .. '\n')
    else
      io.stderr:write('outdated: ' .. path .. '\n')
    end
    return false
  end
  local dir = path:match('(.+)/[^/]+$')
  if dir then
    M.mkdir_p(dir)
  end
  local f = assert(io.open(path, 'w'))
  f:write(content)
  f:close()
  io.write('wrote: ' .. path .. '\n')
  return true
end

function M.extend_lines(dst, src)
  for _, line in ipairs(src) do
    dst[#dst + 1] = line
  end
end

return M
