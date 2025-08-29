local util = require'i18n-menu.util'
local dig = require'i18n-menu.dig'

--- @class blink.cmp.Source
local M = {}

function M.new()
  local o = {}
  return setmetatable(o, { __index = M })
end

function M:get_trigger_characters()
  return {"'", '`', '.', '"'}
end

function M:enabled()
  local ft = vim.bo.filetype
  return ft == 'javascript' or ft == 'javascriptreact'
end

function M:get_completions(ctx, callback)
  local items = {}
  -- callback = vim.schedule_wrap(callback)
  local pos = ctx.bounds.start_col-2
  local start = pos+1
  local found = false
  while start > 0 do
    local char = string.sub(ctx.line, start, start)
    if char:match("[%w%d_.]") == nil then
      found = char == "'" or char == '`' or char == '"'
      found = found and string.sub(ctx.line, start-3, start-1) == '_t('
      break
    end
    start = start-1
  end
  if found then
    local translations = util.load_translations(util.get_messages_dir() .. '/en.json')
    if start < pos then
      translations = dig.dig(translations, string.sub(ctx.line, start+1, pos))
    end
    if translations and type(translations) == 'table' then
      for label, value in pairs(translations) do
        if type(value) == 'table' then
          local doc = '{\n'
          local i = 1
          for k, v in pairs(value) do
            if i > 8 then
              doc = doc .. '  ...\n'
              break
            end
            if type(v) == 'table' then v = '{...}' end
            doc = doc .. '  ' .. k .. ': ' .. v .. '\n'
            i = i + 1
          end
          value = doc .. '}'
        end
        table.insert(items, {
          label = label,
          documentation = {
            kind = 'plaintext',
            value = value,
          },
          insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
          kind_name = 'I18n',
          kind_icon = '',
        })
      end
    end
  end
  callback{
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  }
end

return M
