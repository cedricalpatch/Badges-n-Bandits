
describe('bbserver', function()
  local bbserver = require "src.[bb].bb.server_main"
  it('Invalid Client ID', function()
    assert.equal(0, bbserver.CreateUniqueId(nil))
  end)
end)