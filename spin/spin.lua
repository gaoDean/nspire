window = platform.window
center = {
  x = window.width() / 2,
  y = window.height() / 2,
}
totalLength = window.height() * 0.9

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

maxIterations = 600

branchIndex = 1

function getPoint(origin, angle, radius)
  return {
    x = radius * math.cos(angle) + origin.x,
    y = radius * math.sin(angle) + origin.y,
  }
end

function changeBranchDelta(change)
  branches[branchIndex].delta = branches[branchIndex].delta + change
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

function on.construction()
  local saveState = var.recall("data")
  if saveState then
    branches = saveState
  end
  window.invalidate()
end

function on.paint(gc)
  gc:setPen("thin", "smooth")
  local i = 1
  local tmppos = getPoint(center, branches[1].angle, totalLength * branches[1].length)
  local oldTip = getPoint(tmppos, branches[2].angle, totalLength * branches[2].length)
  local starting = oldTip
  while (i < maxIterations) do
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

function on.charIn(char)
  if (char == "+")      then changeBranchDelta(0.1)
  elseif (char == "-")  then changeBranchDelta(-0.1)
  elseif (char == "*")  then totalLength = totalLength + 10
  elseif (char == "/")  then totalLength = totalLength - 10
  end
  window.invalidate()
end

function on.destroy()
  var.store("data", branches)
end
