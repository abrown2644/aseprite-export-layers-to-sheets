local separator = "/"
local spacing = "_"

function exportLayerAsSprite(layer, originalSprite, outputPath)
  app.fs.makeDirectory(app.fs.filePath(outputPath))

  -- Create a new sprite (same size and color mode)
  local newSprite = Sprite(originalSprite.width, originalSprite.height, originalSprite.colorMode)

  -- Add missing frames if needed
  for i = 2, #originalSprite.frames do
    newSprite:newFrame()
  end

  -- Copy cels from the original layer into the new sprite's default layer
  local targetLayer = newSprite.layers[1]

  for i, frame in ipairs(originalSprite.frames) do
    local cel = layer:cel(i)
    if cel then
      local image = cel.image:clone()
      newSprite:newCel(targetLayer, i, image, cel.position)
    end
  end

  -- Export the new sprite
  app.command.ExportSpriteSheet{
    sprite = newSprite,
    ui = false,
    askOverwrite = false,
    type = SpriteSheetType.ROWS,
    columns = 0,
    rows = 0,
    bestFit = true,
    textureFilename = outputPath .. ".png",
    dataFilename = outputPath .. ".json",
    dataFormat = SpriteSheetDataFormat.JSON_ARRAY,
    borderPadding = 0,
    shapePadding = 0,
    innerPadding = 0,
    trimSprite = false,
    trim = false,
    trimByGrid = false,
    extrude = false,
    ignoreEmpty = false,
    mergeDuplicates = false,
    openGenerated = false,
    splitLayers = false,
    listLayers = false
  }

  newSprite:close()
  print("✅ Exported: " .. outputPath)
end

-- MAIN EXPORT LOOP
function exportAll(sprite, basePath)
  for _, group in ipairs(sprite.layers) do
    if group.isGroup then
      local groupName = group.name:gsub("%s+", spacing)

      for _, subgroup in ipairs(group.layers) do
        if subgroup.isGroup then
          local subgroupName = subgroup.name:gsub("%s+", spacing)

          for _, layer in ipairs(subgroup.layers) do
            if not layer.isGroup then
              local layerName = layer.name:gsub("%s+", spacing)
              local exportPath = basePath .. separator .. groupName .. separator .. subgroupName .. separator .. layerName
              exportLayerAsSprite(layer, sprite, exportPath)
            end
          end
        end
      end
    end
  end
end

-- === ENTRY POINT ===
local spr = app.activeSprite
if not spr then return app.alert("No active sprite.") end

local exportDir = app.fs.filePath(spr.filename) .. "/exports"

if app.alert{
  title = "Export Each Layer as Spritesheet",
  text = {
    "This will export every numbered layer from each subgroup of each group",
    "Output structure: exports/front/hair/1.png",
    "",
    "Continue?"
  },
  buttons = { "&Yes", "&Cancel" }
} ~= 1 then
  return
end

exportAll(spr, exportDir)
