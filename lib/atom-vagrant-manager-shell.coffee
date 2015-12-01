vagrant = require 'node-vagrant'
{$, View} = require 'space-pen'
{ScrollView,TextEditorView} = require 'atom-space-pen-views'
{Client} = require 'ssh2'
fs = require 'fs'

module.exports =
class AtomVagrantManagerShellView extends View
  machine: false
  config: false
  item: false
  conn: false
  stream: false
  connected: false
  pwd: false

  getTitle: ->
    'Vagrant machine: ' + @item.name

  getId: ->
    @item.id

  initialize:(item) ->
    @item = item

  attached: ->
    $this = @
    @output =
      $(@element.querySelector("div[id='atom-vagrant-manager-shell-output']"))

    @pwd =
      $(@element.querySelector("span[id='atom-vagrant-manager-shell-pwd']"))

    $(@filterEditorView).on('keydown',(event)->
      event = event || window.event
      console.log event.keyCode
      if event.keyCode == 13
        $this.executeCommand()
    )
    @init()

  executeCommand: ->
    $this = @
    command = @getCommand()

    if !@connected
      @append('Not connected','error')
      return

    if command == 'clear'
      @output.find('> div').remove()
      return @clearCommand()

    @append(command,'command')
    @conn.exec(command,(err,stream)->
      stream.on('data',(data)->
        $this.append(data.toString())
      ).stderr.on('data', (data)->
        $this.append(data.toString(),'error')
      )
    )
    @clearCommand()

  init: ->
    $this = @
    machine = vagrant.create cwd : @item.cwd
    machine.sshConfig((err,res) ->
      if err
        return @destroy()
      $this.conn = new Client()
      $this.append('Connecting...','output')
      $this.conn.on('ready',()->
        $this.output.find('*').remove()
        $this.append('Connected')
        $this.connected = true
        $this.setPwd()
      ).on('banner',(data)->
        $this.append(data)
      ).connect({
        host: res.hostname,
        port: res.port,
        username: res.user,
        privateKey: fs.readFileSync res.private_key
      })
    )

  getCommand: ->
    @filterEditorView.getText()

  clearCommand: ->
    @filterEditorView.setText('')

  setPwd: ->
    $this = @
    @conn.exec('pwd',(err,stream)->
      stream.on('data',(data)->
        $this.pwd.text(pwd)
      )
    )



  append:(line,type) ->
    if !type
      type = 'output'

    lines = []

    if type == 'output'
      line.toString().split("\n").forEach((v)->
        lines.push '<div class="line">' + v + '</div>'
      )

      line = lines.join('')
    else
      line = line.toString()


    $this = @

    if  type == 'command'
      @conn.exec('pwd',(err,stream)->
        stream.on('data',(data)->
          pwd = '<span class="pwd">' + data.toString() + '</span>'
          $this.output.append '<div class="line-output command-'+type+'">' + pwd + line + '</div>'
          $this.output.scrollTop($this.output.get(0).scrollHeight)

        ).stderr.on('data', (data)->
          $this.output.append '<div class="line-output command-error">' + line + '</div>'
          $this.output.scrollTop($this.output.get(0).scrollHeight)
        )
      )
    else
      $this.output.append '<div class="line-output command-'+type+'">' + line + '</div>'
      $this.output.scrollTop($this.output.get(0).scrollHeight)

    if @connected
      @setPwd()

  @content: ->
    @div class : 'atom-vagrant-manager-shell-wrapper', =>
      @div id : 'atom-vagrant-manager-shell-output'
      @span id : 'atom-vagrant-manager-shell-pwd'
      @subview 'filterEditorView', new TextEditorView(mini: true)
