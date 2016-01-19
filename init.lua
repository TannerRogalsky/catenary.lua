-- Adapted from valrus' Processing implementation. https://github.com/valrus/catenary

local cosh, sinh, log, sqrt, abs = math.cosh, math.sinh, math.log, math.sqrt, math.abs
local function asinh(x)
  return log(x + sqrt(1 + x*x))
end

local function xshift(a, x1, y1, x2, y2)
  -- Calculate the horizontal shift necessary to put the catenary in the right place.
  -- This expression is derived from solving the system:
  --    y1 = a * cosh((x1 - x0)/d) + y0
  --    y2 = a * cosh((x2 - x0)/d) + y0
  -- where (x1, y1) and (x2, y2) are the endpoints and x0 and y0 are the horizontal and
  -- vertical shifts.
  -- (The derivation uses substitution for y0 and the hyperbolic trig identity
  --  for cosh A - cosh B.)
  return ((x1 + x2)/2) - (a * asinh((y2 - y1)/(2*a*sinh((x2-x1)/(2*a)))))
end

local function yshift(a, b0, x1, y1)
  -- The other half of the solution to the system described above in xshift.
  return y1 - (a * cosh((x1 - b0)/a))
end

local function newtonGuess(h, k, length)
  -- Return a decent enough guess that Newton's method appears to take about 7 iterations
  -- to get within .001 of the correct parameter.
  -- Rationale: the equation in catenaryParameter looks similar to the graph of y = 1/(x^2) - C.
  -- Guessing too high causes Newton's Method to diverge, as we land out where the slope
  -- of the tangent is very shallow. But guessing too low can cause an overflow error
  -- because of the exponentiation in sinh.
  -- We guess so that sinh(h/2a) is equal to sqrt(l^2 - k^2).
  -- This is a low guess it puts us on the left side of the root, where y is positive, because
  -- of the multiplication by 2a (which is always > 1 because we're measuring in pixels).
  -- But that additional factor of 2a won't be enough to cause an overflow.
  return abs(h / (asinh(sqrt(length*length-k*k))))
end

local function catenaryParameter(a, h, k, length)
  -- Equation from http://en.wikipedia.org/wiki/Catenary#Determining_parameters
  -- (second to last equation in that section)
  return 2*a*sinh(h/(2*a)) - sqrt(length*length - k*k)
end

local function catenaryParamDerivative(a, h)
  -- Derivative of the above. Used in Newton's method to solve for the parameter a,
  -- since (as Wikipedia notes) the equation above is transcendental in a.
  return 2*sinh(h/(2*a)) - (h/a)*cosh(h/(2*a))
end

local function newton(h, k, length, guess)
  -- This is a 100% straightforward implementation of Newton's method. I haven't
  -- found any instances where it gets anywhere near the max number of iterations if it does,
  -- it will probably fail spectacularly. In my experience, overflows are much more common.
  -- Still fails for extremely steep slopes. Not sure I really care.
  local x0 = 1
  local x1 = guess
  local fx = 1
  local iterations = 0
  while (abs(fx) > 0.001 and iterations < 5000) do
    x0 = x1
    fx = catenaryParameter(x0, h, k, length)
    local dfx = catenaryParamDerivative(x0, h)
    x1 = x0 - (fx/dfx)
    iterations = iterations + 1
  end
  if (iterations >= 5000) then
    -- Newton's method failed, return the guess and hope it's good enough, probably not
    return abs(guess)
  else
    -- Newton's method successful
    return abs(x1)
  end
end

local function catenary(x, a, x1, y1, x2, y2)
  -- The equation for a catenary, with horizontal and vertical shifts to put the vertex
  -- where it needs to be to pass through the endpoints of the user-traced line segment.
  local x0 = xshift(a, x1, y1, x2, y2)
  return a * cosh((x - x0)/a) + yshift(a, x0, x1, y1)
end

local function Catenary(x1, y1, x2, y2, length)
  local instance = {
    updatePoints = function(self, newX1, newY1, newX2, newY2, length)
      self.x1, self.y1, self.x2, self.y2 = newX1, newY1, newX2, newY2
      self.length = length or self.length

      self.h = abs(self.x2 - self.x1)
      self.k = abs(self.y2 - self.y1)

      local guess = newtonGuess(self.h, self.k, self.length)
      self.a = -1 * newton(self.h, self.k, self.length, guess)
    end
  }

  instance:updatePoints(x1, y1, x2, y2, length)

  return setmetatable(instance, {
    __index = function(self, x)
      local v = rawget(self, x)
      if v == nil then
        return catenary(x, self.a, self.x1, self.y1, self.x2, self.y2)
      else
        return v
      end
    end
  })
end

return Catenary
