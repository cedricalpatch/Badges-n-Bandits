
describe('bbserver', function()
  local bbserver = require "src.[bb].bb.main_server"
  it('Invalid Client ID', function()
    assert.equal(0, bbserver.CreateUniqueId())
  end)
end)