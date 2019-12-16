
describe('bbserver', function()
  local bbserver = require "[bb]/bb/main_server"
  it('Invalid Client ID', function()
    assert.equal(0, bbserver.CreateUniqueId(nil))
  end)
end)