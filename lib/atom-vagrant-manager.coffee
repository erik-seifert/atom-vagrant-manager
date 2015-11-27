AtomVagrantManagerView = require './atom-vagrant-manager-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomVagrantManager =
  atomVagrantManagerView: null
  panel: null
  subscriptions: null

  activate: (state) ->
    @atomVagrantManagerView = new AtomVagrantManagerView(state.atomVagrantManagerViewState)
    @panel =  atom.workspace.addRightPanel(item: @atomVagrantManagerView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-vagrant-manager:toggle': => @toggle()

  deactivate: ->
    @panel.destroy()
    @subscriptions.dispose()
    @atomVagrantManagerView.destroy()

  serialize: ->
    atomVagrantManagerViewState: @atomVagrantManagerView.serialize()

  toggle: ->
    console.log 'AtomVagrantManager was toggled!'

    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()
