
-- Unit Testing
local bbserver = require '/src/[bb]/bb/server_main.lua'

describe('bbserver', function()
  it('Invalid Client ID', function()
    assert.equal(0, bbserver.CreateUniqueId())
  end)
end)