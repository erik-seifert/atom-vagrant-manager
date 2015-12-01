vagrant = require 'node-vagrant'
{$, View} = require 'space-pen'
{ScrollView} = require 'atom-space-pen-views'
AtomVagrantManagerShellView = require './atom-vagrant-manager-shell'

module.exports =
class AtomVagrantManagerView extends View
  list: null
  version: null
  installed: false
  states: []
  timeout: null
  interval: 5000
  view: false

  initialize: ->
    atom.commands.add @element,
      'core:move-up': => @scrollUp()
      'core:move-down': => @scrollDown()
      'core:page-up': => @pageUp()
      'core:page-down': => @pageDown()
      'core:move-to-top': => @scrollToTop()
      'core:move-to-bottom': => @scrollToBottom()

  @content: ->
    @div class : 'atom-vagrant-manager-detail-wrapper', =>
      @h1 class: 'header', 'Vagrant Manager'
      @div id: 'atom-vagrant-manager-id', =>
        @span class: 'badge badge-flexible info'
      @div class: 'btn-group', =>
        @button {class: 'btn icon green icon-triangle-right start-all', id: 'atom-vagrant-manager-start-all'},'Start all'
        @button {class: 'btn icon red icon icon-primitive-square stop-all', id: 'atom-vagrant-manager-stop-all'}, 'Stop all'
      @div id: 'atom-vagrant-manager-list', =>
        @div class: 'panel-group'

  isInstalled:(cb) ->
    vagrant.version( (err, out) ->
      cb(err,out)
    )

  initShellView:(item) ->
    console.log 'Init shell view'
    view = new AtomVagrantManagerShellView(item)
    console.log '--- init ----'
    pane = atom.workspace.getActivePane()
    item = pane.addItem view, 0
    pane.activateItem item

  attached: ->
    @version =
      $(@element.querySelector("div[id='atom-vagrant-manager-id'] > span"))
    @list =
      $(@element.querySelector("div[id='atom-vagrant-manager-list'] > div"))

    $startAll =
      $(@element.querySelector("button[id='atom-vagrant-manager-start-all']"))
    $stopAll =
      $(@element.querySelector("button[id='atom-vagrant-manager-stop-all']"))

    $this = @
    @isInstalled( (err,version) ->
      if !err && version
        $this.installed = true
        versionNumber = version.match /(\d+\.\d+.\d+)/
        $this.version.text  versionNumber[0]
        $this.version.addClass 'info'
        callback = -> $this.initVagrant()
        callback()
        $startAll.bind('click', ->
          console.log('Click start')
          $this.startAll()
        )
        $stopAll.bind('click', ->
          console.log('Click stop')
          $this.stopAll()
        )
        $this.timeout = setInterval callback, $this.interval

      else
        $this.version.addClass 'danger'
    )

  initVagrant: ->
    if !@installed
      return
    $this = @
    vagrant.globalStatus((err,states) ->
      if err
        $this.states = []
        $this.attachStates()
        return err
      console.log states
      $this.states = states
      $this.attachStates()
    )

  attachStates: ->
    list = @list
    $this = @
    list.find('> div').remove()

    @states.forEach((v) ->
      item = $($this.viewItem(v))
      item.addClass(v.state).addClass('list-group-item')
      item.data 'item',v
      list.append(item)
    )

    list.find('button.stop,button.start').bind( 'click', ->
      item = $(this).parents('.panel').eq(0).data('item')
      $this.toggleMachine item
    )

    list.find('button.shell').bind( 'click', ->
      item = $(this).parents('.panel').eq(0).data('item')
      $this.initShellView item
    )

  startShell:(item) ->


  stopAll: ->
    @states.forEach((v)->
      machine = vagrant.create({cwd : v.cwd})
      machine.halt((err,res) ->

      )
    )

  startAll: ->
    @states.forEach((v)->
      machine = vagrant.create({cwd : v.cwd})
      machine.up((err,res) ->
      )
    )

  toggleMachine:(item) ->

    machine = vagrant.create cwd:item.cwd
    machine.status((err,res) ->
      if err
        return
      if res.default
        status = res.default.status
      else if res[item.name]
        status = res[item.name].status
      console.log 'Status',status
      if status == 'running'
        machine.halt((err,res) ->
          console.log res
          console.log err
        )
      else if status == 'poweroff'
        machine.up((err,res) ->
          console.log res
          console.log err
        )
    )


  viewItem:(item) ->
    return  '<div class="panel atom-panel">' +
              '<div class="panel-heading">'  + item.name + '</div>' +
              '<div class="panel-body">'  +
                'ID: ' + item.id + '<br>' +
                'Provider: ' + item.provider + ''+
              '</div>' +
              '<div class="panel-footer">'  +
              '<div class="btn-group">' +
                '<button class="stop btn icon icon-primitive-square red">' +
                  'Stop' +
                '</button>' +
                '<button class="start btn icon icon-triangle-right green">' +
                  'Start' +
                '</button>' +
                '<button class="shell btn icon icon-triangle-right green">' +
                  'Shell' +
                '</button>' +
              '</div>' +
              '</div>' +
            '</div>'

  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    if @timeout
      clearTimeout(@timeout)

  getElement: ->
    @element
