--[[
  Pandoc Lua filter:
  1. Renders ```mermaid code blocks as PNG images via mmdc.
  2. Strips emoji characters from headings (they don't render well in PDF/LaTeX).

  Requires: @mermaid-js/mermaid-cli (mmdc) installed globally.
  Usage: pandoc --lua-filter filters/mermaid.lua -o output.pdf input.md
]]

local counter = 0

-- Puppeteer config for headless rendering (--no-sandbox for CI environments)
local puppeteer_config = '{"args":["--no-sandbox","--disable-setuid-sandbox"]}'

-- Pattern to match common emoji Unicode ranges
local function strip_emoji(text)
  -- Remove emoji and variation selectors, keeping basic text
  -- This covers most common emoji ranges
  local result = text
  -- Remove emoji characters (various Unicode ranges)
  result = result:gsub("[\xF0\x9F][\x80-\xBF][\x80-\xBF][\x80-\xBF]", "")  -- U+1F000-1FFFF
  result = result:gsub("\xE2[\x9C-\xAD][\x80-\xBF]", "")  -- various symbols
  result = result:gsub("\xE2[\xB0-\xBF][\x80-\xBF]", "")  -- misc symbols
  result = result:gsub("\xE2\x8F[\x80-\xBF]", "")  -- clock symbols
  result = result:gsub("\xE2\x9A[\x80-\xBF]", "")  -- misc symbols
  result = result:gsub("\xEF\xB8\x8F", "")  -- variation selector
  result = result:gsub("\xE2\x83\xA3", "")  -- combining enclosing keycap
  -- Clean up resulting double spaces
  result = result:gsub("  +", " ")
  result = result:gsub("^ +", "")
  return result
end

function Header(el)
  -- Strip emoji from header text for clean PDF rendering
  return el:walk({
    Str = function(s)
      local cleaned = strip_emoji(s.text)
      if cleaned ~= s.text then
        if cleaned == "" then
          return {}
        end
        return pandoc.Str(cleaned)
      end
    end
  })
end

function CodeBlock(block)
  -- Only process mermaid code blocks
  if not block.classes:includes("mermaid") then
    return nil
  end

  counter = counter + 1

  -- Write mermaid source to temp files
  local base = os.tmpname()
  local input_file = base .. ".mmd"
  local output_file = base .. ".png"
  local config_file = base .. ".json"

  -- Helper to clean up all temp files
  local function cleanup()
    os.remove(base)
    os.remove(input_file)
    os.remove(output_file)
    os.remove(config_file)
  end

  -- Write puppeteer config
  local cf = io.open(config_file, "w")
  cf:write(puppeteer_config)
  cf:close()

  -- Write mermaid code
  local f = io.open(input_file, "w")
  f:write(block.text)
  f:close()

  -- Run mmdc to render the diagram
  local cmd = string.format(
    'mmdc -i "%s" -o "%s" -p "%s" -b transparent -w 1200 -s 2 2>&1',
    input_file, output_file, config_file
  )
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  local success = handle:close()

  if success then
    -- Read the generated image
    local img_f = io.open(output_file, "rb")
    if img_f then
      local img_data = img_f:read("*a")
      img_f:close()
      cleanup()

      -- Create an image element and store in media bag
      local fname = "mermaid-" .. counter .. ".png"
      pandoc.mediabag.insert(fname, "image/png", img_data)

      return pandoc.Para({ pandoc.Image({}, fname, "", { width = "100%" }) })
    end
  end

  -- If rendering failed, clean up and keep the original code block
  cleanup()
  io.stderr:write("WARNING: Failed to render mermaid diagram #" .. counter .. "\n")
  io.stderr:write(result .. "\n")
  return nil
end
