traverse = 'topdown'

local pendingItem = nil
local pendingComment = nil

function Span(el)
  if not el.classes then
    return el
  elseif el.classes:includes("dropcap") then
    local text = pandoc.utils.stringify(el.content)
    local first = text:sub(1, 1)
    local rest = text:sub(2)
    return pandoc.RawInline("latex",
        "\\DndDropCapLine{" .. first .. "}{" .. rest .. "}")
  elseif el.classes:includes("item-type") and pendingItem then
    local inline = pendingItem .. "{" .. pandoc.utils.stringify(el.content) .. "}"
    pendingItem = nil
    return pandoc.RawInline("latex", inline)
  end
  return el
end

function BlockQuote(el)
  local content = pandoc.write(pandoc.Pandoc(el.content), "latex")
  local text = ""
  if pendingComment then
    text = pendingComment
    pendingComment = nil
  end
  local comment = "\\begin{DndComment}{" .. text .. "}\n" ..
    content .. "\n" ..
    "\\end{DndComment}"
  return pandoc.RawBlock("latex", comment)
end

function Header(el)
  pendingItem = nil
  if not el.classes then
    return el
  elseif el.classes:includes("item") then
    pendingItem = "\\DndItemHeader{" .. pandoc.utils.stringify(el.content) .. "}"
    return {}
  elseif el.classes:includes("comment") then
    pendingComment = pandoc.utils.stringify(el.content)
    return {}
  end
  return el
end

local function alignmentSpec(alignment)
  if alignment == "AlignRight" then
    return "r"
  elseif alignment == "AlignCenter" then
    return "c"
  else
    return "X"
  end
end

-- Main function to transform tables
function Table(el)
  local latex = ""

  -- Column specification
  local colspec = "{"
  for _, colspec_ in ipairs(el.colspecs) do
    colspec = colspec .. alignmentSpec(colspec_[1])
  end
  colspec = colspec .. "}"

  -- Use table caption as the DndTable header.
  local header = ""
  if el.caption and el.caption.long and #el.caption.long > 0 then
    for _, block in ipairs(el.caption.long) do
      header = header .. pandoc.utils.stringify(block.content)
    end
  end

  -- begin
  if header ~= "" then
    latex = "\\begin{DndTable}[header=" .. header .. "]" .. colspec .. "\n"
  else
    latex = "\\begin{DndTable}" .. colspec .. "\n"
  end

  -- header rows
  if el.head and el.head.rows and #el.head.rows > 0 then
    for _, row in ipairs(el.head.rows) do
      local headerRow = ""
      for i, cell in ipairs(row.cells) do
        local content = pandoc.utils.stringify(cell.contents)
        headerRow = headerRow .. "\\textbf{" .. content .. "}"
        if i < #row.cells then
          headerRow = headerRow .. " & "
        end
      end
      latex = latex .. headerRow .. " \\\\\n"
    end
  end

  -- body rows
  for _, body in ipairs(el.bodies) do
    for j, row in ipairs(body.body) do
      local bodyRow = ""
      for i, cell in ipairs(row.cells) do
        bodyRow = bodyRow .. pandoc.utils.stringify(cell.contents)
        if i < #row.cells then
          bodyRow = bodyRow .. " & "
        end
      end
      latex = latex .. bodyRow
      if j < #body.body then
        latex = latex .. " \\\\"
      end
      latex = latex .. "\n"
    end
  end

  -- end
  latex = latex .. "\\end{DndTable}"

  return pandoc.RawBlock("latex", latex)
end
