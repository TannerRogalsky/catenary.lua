# Catenary
## API
`instance = Catenary(x1, y1, x2, y2, length)`: constructor
`instance:updatePoints(x1, y1, x2, y2, length = oldLength)`: updates the catenary control points. `length` defaults to the previous value.
`y = instance[x]`: gets the `y` coordinate for a given `x` where x1 < x < x2. Otherwise, `y` is undefined.

## Example
A sample program to get every coordinate for a given catenary.

```lua
local Catenary = require('catenary')

local a = {x = 80, y = 360}
local b = {x = 170, y = 380}
local length = 100

catenary = Catenary(a.x, a.y, b.x, b.y, length)

local points = {}
for x=a.x,b.x do
  table.insert(points, x)
  table.insert(points, catenary[x])
end
print(unpack(points))
```
