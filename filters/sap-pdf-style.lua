local methods = {
  ["Method 1: Fabric Data Factory extraction"] = {
    color = "D97706",
    marker = "M1",
    title = "Fabric Data Factory extraction",
  },
  ["Method 2: Mirroring for SAP through SAP Datasphere"] = {
    color = "2E7D32",
    marker = "M2",
    title = "Mirroring through SAP Datasphere",
  },
  ["Method 3: Copy Job CDC through SAP Datasphere Outbound"] = {
    color = "558B2F",
    marker = "M3",
    title = "Copy Job CDC through SAP Datasphere",
  },
  ["Method 4: semantic federation"] = {
    color = "1565C0",
    marker = "M4",
    title = "Semantic federation",
  },
  ["Method 5: SAP Datasphere governed data exchange"] = {
    color = "00796B",
    marker = "M5",
    title = "SAP Datasphere governed exchange",
  },
  ["Method 6: event-driven integration"] = {
    color = "C2410C",
    marker = "M6",
    title = "Event-driven integration",
  },
  ["Method 7: Open Mirroring partner solutions"] = {
    color = "4338CA",
    marker = "M7",
    title = "Open Mirroring partners",
  },
  ["Method 8: SAP Business Data Cloud Connect for Microsoft Fabric"] = {
    color = "AD1457",
    marker = "M8",
    title = "SAP Business Data Cloud Connect",
  },
}

function Pandoc(document)
  local blocks = {}

  for _, block in ipairs(document.blocks) do
    if block.t == "Header" and block.level == 2 then
      local title = pandoc.utils.stringify(block.content)
      local method = methods[title]

      if method then
        local banner = string.format(
          "\\clearpage\n\\methodbanner{%s}{%s}{%s}",
          method.color,
          method.marker,
          method.title
        )
        table.insert(blocks, pandoc.RawBlock("latex", banner))
      elseif title == "Legacy Azure Data Factory SAP CDC: review required" then
        table.insert(
          blocks,
          pandoc.RawBlock("latex", "\\clearpage\n\\resetsectioncolor")
        )
      end
    end

    table.insert(blocks, block)
  end

  document.blocks = blocks
  return document
end
