local window = platform.window
local center = {
  x = window.width() / 2,
  y = window.height() / 2,
}
local totalLength = window.height() * 0.7
local message = ""
local recallSave = false
local branchIndex = 1
local iterations = 1
local tmpDataSave = nil

local debug = nil
local fastDraw = nil
local branches = nil
local saves = nil
local maxIterations = nil
local iterationDelta = nil

function toggleDebug()    debug     = not debug end
function toggleFastDraw() fastDraw  = not fastDraw end
function resetSaves() saves = {} end
function resetData()
  branches = {
    {
      angle = 0,
      length = 0.5,
      delta = 5
    },
    {
      angle = 0,
      length = 0.5,
      delta = 5
    }
  }
  maxIterations = 500
  debug = false
  fastDraw = false
  iterationDelta = 10
end

local menu = {
  {"Options",
    {"Toggle debug", toggleDebug},
    {"Toggle fast draw", toggleFastDraw},
    {"Reset variables", resetData}
    {"Reset saves", resetSaves}
  }
}
toolpalette.register(menu)

function deepCopy(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[deepCopy(k, s)] = deepCopy(v, s) end
    return setmetatable(res, getmetatable(obj))
end

function getPoint(origin, angle, radius)
  return {
    x = radius * math.cos(angle) + origin.x,
    y = radius * math.sin(angle) + origin.y,
  }
end

function changeBranchLength(change)
  if branchIndex == 1 then
    branches[1].length = branches[1].length + change
    branches[2].length = branches[2].length - change
  else
    branches[2].length = branches[2].length + change
    branches[1].length = branches[1].length - change
  end
end

function updateSaveSlot(slot)
  slot = tonumber(slot)
  if recallSave and saves[slot] then
    message = "recall"
    tmpDataSave = compileData() -- keep tmp copy of current branch
    restoreData(saves[slot])
    recallSave = false
  else
    message = "slot"
    saves[slot] = compileData() -- save current configuration
  end
end

function on.construction()
  resetData()
  resetSaves()
  timer.start(0.1)
end

function on.paint(gc)
  if debug then
    gc:drawString(message, 4, 20)
  end
  gc:setPen("thin", "smooth")
  local i = 1
  branches[1].angle = 0
  branches[2].angle = 0
  local tmppos = getPoint(center, branches[1].angle, totalLength * branches[1].length)
  local oldTip = getPoint(tmppos, branches[2].angle, totalLength * branches[2].length)
  local starting = oldTip
  while (i <= iterations) do
    branches[1].angle = branches[1].angle + branches[1].delta
    branches[2].angle = branches[2].angle + branches[2].delta
    local pos = getPoint(center, branches[1].angle, totalLength * branches[1].length)
    local tip = getPoint(pos, branches[2].angle, totalLength * branches[2].length)
    if (i > 1 and tip.x == starting.x and tip.y == starting.y) then
      break
    end
    gc:drawLine(oldTip.x, oldTip.y, tip.x, tip.y)
    oldTip = tip
    i = i + 1
  end
end

function on.timer()
  if fastDraw then
    iterations = maxIterations
    window.invalidate()
    timer.stop()
    return
  end
  window.invalidate()
  iterations = iterations + iterationDelta
  if iterations > maxIterations then
    timer.stop()
  end
end

function on.arrowUp()
  branchIndex = 2
end

function on.arrowDown()
  branchIndex = 1
end

function on.arrowLeft()
  changeBranchLength(0.1)
  window.invalidate()
end

function on.arrowRight()
  changeBranchLength(-0.1)
  window.invalidate()
end

function on.enterKey()
  timer.stop()
end

function on.charIn(char)
  message = char
  if     char == "+"    then branches[branchIndex].delta = branches[branchIndex].delta + 0.1
  elseif char == "-"    then branches[branchIndex].delta = branches[branchIndex].delta - 0.1
  elseif char == "*"    then totalLength = totalLength + 10
  elseif char == "/"    then totalLength = totalLength - 10
  elseif char == ")"    then maxIterations = maxIterations + 50
  elseif char == "("    then maxIterations = maxIterations - 50
  elseif char == "x"    then iterationDelta = iterationDelta + 1
  elseif char == "y"    then iterationDelta = iterationDelta - 1
  elseif char == "."    then recallSave = true
  elseif char == "-"    then if tmpDataSave then restoreData(tmpDataSave) end
  elseif tonumber(char) then updateSaveSlot(char)
  end
  iterations = 1
  timer.start(0.1)
end

function compileData()
  return {
    branches = deepCopy(branches),
    totalLength = totalLength,
    saves = saves,
    maxIterations = maxIterations,
    debug = debug,
    fastDraw = fastDraw,
  }
end

function restoreData(data)
  branches = data.branches
  totalLength = data.totalLength
  saves = data.saves
  maxIterations = data.maxIterations
  debug = data.debug
  fastDraw = data.fastDraw
end

function on.save()
  return compileData()
end

function on.restore(data)
  restoreData(data)
  window.invalidate()
end
