local separator = "/"
local spacing = "_"

function ExportCombinedLayersBySubgroup(sprite, exportDir)
  local layerMap = {}

  -- Step 1: Group layers by subgroup name and numeric layer name
  for _, group in ipairs(sprite.layers) do
    if group.isGroup then
      local groupName = group.name:gsub("%s+", spacing)

      for _, subgroup in ipairs(group.layers) do
        if subgroup.isGroup then
          local subgroupName = subgroup.name:gsub("%s+", spacing)

          -- Collect layers and sort by numeric name
          local numberedLayers = {}
          for _, layer in ipairs(subgroup.layers) do
            if not layer.isGroup then
              local numericIndex = tonumber(layer.name)
              if numericIndex ~= nil then
                table.insert(numberedLayers, { index = numericIndex, layer = layer })
              end
            end
          end

          table.sort(numberedLayers, function(a, b)
            return a.index < b.index
          end)

          for _, entry in ipairs(numberedLayers) do
            local layerKey = subgroupName .. separator .. tostring(entry.index)
            if not layerMap[layerKey] then
              layerMap[layerKey] = {}
            end
            table.insert(layerMap[layerKey], {
              group = groupName,
              layer = entry.layer
            })
          end
        end
      end
    end
  end

  -- Step 2: Build combined spritesheets
  for key, entries in pairs(layerMap) do
    local subgroupName, index = key:match("([^/]+)" .. separator .. "([^/]+)")
    local frameCount = #sprite.frames
    local frameWidth = sprite.width
    local frameHeight = sprite.height
    local sheetWidth = frameWidth * frameCount
    local sheetHeight = frameHeight * #entries

    local combinedSprite = Sprite(sheetWidth, sheetHeight, sprite.colorMode)
    local finalImage = Image(sheetWidth, sheetHeight, sprite.colorMode)

    for rowIndex, entry in ipairs(entries) do
      for frameIndex, frame in ipairs(sprite.frames) do
        local cel = entry.layer:cel(frameIndex)
        if cel then
          local srcImage = cel.image
          local dstX = (frameIndex - 1) * frameWidth
          local dstY = (rowIndex - 1) * frameHeight
          finalImage:drawImage(srcImage, dstX + cel.position.x, dstY + cel.position.y)
        end
      end
    end

    combinedSprite:newCel(combinedSprite.layers[1], 1, finalImage, Point(0, 0))

    local outPath = exportDir .. separator .. subgroupName
    app.fs.makeDirectory(outPath)
    local filePath = outPath .. separator .. index

    app.command.ExportSpriteSheet{
      sprite = combinedSprite,
      ui = false,
      askOverwrite = false,
      type = SpriteSheetType.NONE,
      columns = 1,
      rows = 1,
      textureFilename = filePath .. ".png",
      dataFilename = filePath .. ".json",
      dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
      borderPadding = 0,
      shapePadding = 0,
      innerPadding = 0,
      trimSprite = false,
      extrude = false,
      ignoreEmpty = false,
      mergeDuplicates = false,
      openGenerated = false
    }

    print("✅ Exported combined: " .. filePath .. ".png")
    combinedSprite:close()
  end
end

-- === ENTRY POINT ===
local spr = app.activeSprite
if not spr then return app.alert("No active sprite.") end

local fileBase = "unsaved_sprite"
if spr.filename and #spr.filename > 0 then
  fileBase = spr.filename:match("([^/\\]+)%.aseprite$") or "unsaved_sprite"
end

local exportDir = app.fs.filePath(spr.filename or app.fs.userConfigPath) .. "/exports/" .. fileBase

if app.alert{
  title = "Export Combined Layers",
  text = {
    "This will combine each indexed layer from all groups (front/back/left/right)",
    "into a single spritesheet per numeric layer in each subgroup.",
    "",
    "Output path:",
    exportDir,
    "",
    "Continue?"
  },
  buttons = { "&Yes", "&Cancel" }
} ~= 1 then
  return
end

ExportCombinedLayersBySubgroup(spr, exportDir)
