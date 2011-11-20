helpers  = require '../src/helpers'


describe 'helpers', ->
  it 'should filter file list for dotfiles and directories', ->
    dependencyPaths = helpers.filterFiles [
      'ConsoleDummy.js'
      '.to_be_ignored'
      'should_be_ignored'
      '#to_be_ignored#'
    ], 'test/fixtures/alternate_base/src/vendor'
    expect(dependencyPaths).toEqual ['ConsoleDummy.js']
