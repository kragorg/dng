local pendingItem = nil
local pendingComment = nil
local documentTitle = nil

local function alignmentSpec(alignment)
  if alignment == "AlignRight" then
    return "r"
  elseif alignment == "AlignCenter" then
    return "c"
  else
    return "X"
  end
end

local LaTeXFilter = {
  Span = function(el)
    if not el.classes then
      return el
    elseif el.classes:includes("dropcap") then
      local text = pandoc.utils.stringify(el.content)
      local first = text:sub(1, 1)
      local rest = text:sub(2)
      return pandoc.RawInline("latex",
          "\\DndDropCapLine{" .. first .. "}{" .. rest .. "}")
    elseif el.classes:includes("break") then
      return pandoc.RawInline("latex", "\\vfill\\break\n")
    elseif el.classes:includes("item-type") and pendingItem then
      local inline = pendingItem .. "{" .. pandoc.utils.stringify(el.content) .. "}"
      pendingItem = nil
      return pandoc.RawInline("latex", inline)
    end
    return el
  end,

  BlockQuote = function(el)
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
  end,

  Header = function(el)
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
  end,

  Table = function(el)
    local latex = ""

    local colspec = "{"
    for _, colspec_ in ipairs(el.colspecs) do
      colspec = colspec .. alignmentSpec(colspec_[1])
    end
    colspec = colspec .. "}"

    local header = ""
    if el.caption and el.caption.long and #el.caption.long > 0 then
      for _, block in ipairs(el.caption.long) do
        header = header .. pandoc.utils.stringify(block.content)
      end
    end

    if header ~= "" then
      latex = "\\begin{DndTable}[header=" .. header .. "]" .. colspec .. "\n"
    else
      latex = "\\begin{DndTable}" .. colspec .. "\n"
    end

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

    latex = latex .. "\\end{DndTable}"

    return pandoc.RawBlock("latex", latex)
  end,

  Para = function(elem)
    local image = elem.content and elem.content[1]
    if not (image.t == "Image") then
      return nil
    end
    return pandoc.Para {
      pandoc.RawInline("latex", "\\begin{figure*}[b]\n"),
      image,
      pandoc.RawInline("latex", "\n\\end{figure*}\n"),
    }
  end,
}

local HTMLFilter = {{
  Header = function(el)
    if documentTitle == nil then
      documentTitle = pandoc.utils.stringify(el.content)
    end
    return el
  end,
  Pandoc = function(doc)
    local name = documentTitle
    local prefix = doc.meta["prefix"]
    local site = doc.meta["site"]
    if prefix then
      name = prefix .. name
    end
    if site then
      doc.meta.pagetitle = site .. ": " .. name
    else
      doc.meta.pagetitle = name
    end
    local auxOutput = doc.meta["basename"] .. ".json"
    if auxOutput then
      local f, err = io.open(auxOutput, "w")
      if not f then
        io.stderr:write("Could not open " .. auxOutput .. " for writing: " .. err .. "\n")
      else
        local auxData = { title = name }
        f:write(pandoc.json.encode(auxData, false))
        f:close()
      end
    end
    local headerHTML = [[
<header class="header">
<ul class="buttons">
<li><a href="index.html">Index</a></li>
<li><a href="]] .. name .. [[.pdf">PDF</a></li>
</ul>
</header>
]]
    local block = pandoc.RawBlock("html", headerHTML)
    table.insert(doc.blocks, 1, block)
    return doc
  end,
}}

if FORMAT == "latex" then
  return LaTeXFilter
elseif FORMAT == "html" then
  return HTMLFilter
else
  return {}
end
