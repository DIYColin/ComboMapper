#Requires AutoHotkey v2.0
#SingleInstance

class ComboMapper {
  static DoublePress := 500
  static actionHooks := Map('press', true, 'pressRelease', true, 'release', true)
  static defaultConf := {press: false, pressRelease: false, release: false, map: false, default: true}
  static initConf := {press: false, pressRelease: false, release: false, map: false, default: false}

  static setupAction(val){
    Switch(Type(val)){
      Case 'String':
        return (*) => Send(val)
      Case 'Func', 'BoundFunc':
        return val
    }
  }

  mouseMap := Map()

  comboMap := Map()

  currentMap := {val: this.comboMap, prev: false, next: false}

  lastPressed := ''
  pressed := ''
  count := 1
  
  state := Map()

  queue := []
  stopped := true

  __New(){
    this.mapMouse(1, 'LButton', 'L')
    this.mapMouse(2, 'RButton', 'R')
    this.mapMouse(3, 'MButton', 'M')
    this.mapMouse(4, 'XButton1', 'X1')
    this.mapMouse(5, 'XButton2', 'X2')
    this.mapMouse('WU', 'WheelUp', 'WU', false)
    this.mapMouse('WD', 'WheelDown', 'WD', false)
    this.mapMouse('WL', 'WheelLeft', 'WL', false)
    this.mapMouse('WR', 'WheelRight', 'WR', false)
  }

  mapMouse(index, trigger, button := '', release := true){
    this.mouseMap['*' trigger] := {index: index, handle: (_, key) => this.press(key)}
    if(release){
      this.mouseMap['*' trigger ' Up'] := {index: index, handle:  (_, key) => this.release(key)}
    }
    if(button){
      if(release){
        bpress := (*) => Click(button, 'D')
        brelease := (*) => Click(button, 'U')
      }else{
        bpress := (*) => Click(button)
        brelease := false
      }
    }else{
      bpress := false
      brelease := false
    }
    this.state[index] := {trigger: trigger, bpress: bpress, brelease: brelease, release: release, config: false, map: false, unset: true}
  }

  mapCombo(trigger, config){

    newconfig := ComboMapper.initConf.Clone()
    for key, val in config.OwnProps() {
      if(ComboMapper.actionHooks.Has(key)){
        val := ComboMapper.setupAction(val)
      }
      newconfig.DefineProp(key, {value: val})
    }
    current := trigger[1]
    currentMap := this.comboMap
    currentKey := 0
    count := 0
    loop(trigger.Length){
      if(current = trigger[A_Index]){
        ++count
      }else{
        currentKey[count].map := currentMap := currentKey[count].map || Map()
        current := trigger[A_Index]
        count := 1
      }
      if(this.state[current].unset){
        Hotkey('*' this.state[current].trigger, (key) => (this.handle(key)))
        if(this.state[current].release){
          Hotkey('*' this.state[current].trigger ' Up', (key) => (this.handle(key)))
        }
        this.state[current].unset := false
      }
      if(currentMap.Has(trigger[A_Index])){
        currentKey := currentMap[trigger[A_Index]]
      }else{
        currentMap[trigger[A_Index]] := currentKey := []
      }
      if(count > currentKey.Length){
        if(A_Index = trigger.Length){
          currentKey.Push(newconfig)
        }else{
          currentKey.Push(ComboMapper.defaultConf)
        }
      }
    }
  }

  handle(key){
    this.queue.Push(key)

    if(this.stopped){
      this.stopped := false
      while(this.queue.Length){
        config := this.mouseMap[this.queue.RemoveAt(1)]
        config.handle(config.index)
      }
      this.stopped := true
    }
  }

  press(mouseKey){
    state := this.state[mouseKey]
    if(!state.config){
      currentMap := this.currentMap
      loop{
        currentKey := currentMap.val.Get(mouseKey, false)
        if(currentKey){
          if(this.lastPressed = mouseKey && A_TickCount - this.pressed < ComboMapper.DoublePress){
            this.count := Mod(this.count, currentKey.Length) + 1
          }else{
            this.count := 1
          }
          currentConf := currentKey[this.count]
          currentMap := false
          break
        }
        if(!(currentMap := currentMap.prev)){
          currentConf := ComboMapper.defaultConf
          break
        }
      }
  
      state.config := currentConf
  
      this.lastPressed := mouseKey
      this.pressed := A_TickCount
  
      if(currentConf.map){
        this.currentMap := this.currentMap.next := state.map := {val: currentConf.map, prev: this.currentMap, next: false}
      }
  
      if(currentConf.default && state.bpress){
        state.bpress()
      }
  
      if(currentConf.press){
        currentConf.press()
      }
  
      if(!state.release){
        this.release(mouseKey)
      }
    }
  }

  release(mouseKey){
    state := this.state[mouseKey]
    currentConf := state.config 
    if(currentConf){
      if(currentConf.pressRelease){
        currentConf.pressRelease()
      }

      if(this.lastPressed = mouseKey && currentConf.release){
        currentConf.release()
      }

      if(currentConf.default && state.brelease){
        state.brelease()
      }
      
      if(state.map){
        state.map.prev.next := state.map.next
        if(state.map.next){
          state.map.next.prev := state.map.prev
        }else{
          this.currentMap := state.map.prev
        }
        state.map := false
      }

      state.config := false
    }
  }
}

cm := ComboMapper()
cm.mapMouse(6, 'F24')
cm.mapCombo([1, 4], {press: '{ctrl down}', pressRelease: '{ctrl up}'})     ;-- Drag and Drop Datei kopieren, FancyZones select multiple
cm.mapCombo([1, 5], {press: '{shift down}', pressRelease: '{shift up}'})   ;-- Drag and Drop Datei verschieben
cm.mapCombo([3, 2], {release: '^+i'})                                      ;-- Entwicklertools öffnen
cm.mapCombo([3, 3], {release: '^w'})                                       ;-- Tab schließen
cm.mapCombo([3, 3, 'WU'], {press: '^#{left}'})                             ;-- vorheriger Virtueller Desktop
cm.mapCombo([3, 3, 'WD'], {press: '^#{right}'})                            ;-- nächster Virtueller Desktop
cm.mapCombo([3, 3, 4, 'WU'], {press: (*) => (                              ;-- vorheriger Virtueller Desktop Fenster mitnehmen
  Title := WinGetTitle('A'),
  WinSetExStyle('^0x80', Title),
  Send('^#{left}'),
  sleep(50),
  WinSetExStyle('^0x80', Title),
  WinActivate(Title)
)})
cm.mapCombo([3, 3, 4, 'WD'], {press: (*) => (                              ;-- nächster Virtueller Desktop Fenster mitnehmen
  Title := WinGetTitle('A'),
  WinSetExStyle('^0x80', Title),
  Send('^#{right}'),
  sleep(50),
  WinSetExStyle('^0x80', Title),
  WinActivate(Title)
)})
cm.mapCombo([3, 4], {release: '^t'})                                       ;-- Tab öffnen
cm.mapCombo([3, 4, 5], {release: '^+t'})                                   ;-- Geschlossenen Tab öffnen
cm.mapCombo([3, 5], {release: '^n'})                                       ;-- Fenster öffnen
cm.mapCombo([3, 5, 4], {release: '^+n'})                                   ;-- Incognito Fenster öffnen
cm.mapCombo([3, 'WU'], {press: '^+{tab}'})                                 ;-- Tab zurück
cm.mapCombo([3, 'WD'], {press: '^{tab}'})                                  ;-- Tab vor
cm.mapCombo([4], {release: '^c'})                                          ;-- Kopieren
cm.mapCombo([4, 3], {press: '^f'})                                         ;-- Suchen
cm.mapCombo([4, 3, 'WU'], {press: '+{F3}'})                                ;-- Suchen zurück
cm.mapCombo([4, 3, 'WD'], {press: '{F3}'})                                 ;-- Suchen weiter
cm.mapCombo([4, 5], {release: '^x'})                                       ;-- Ausschneiden
cm.mapCombo([4, 6], {release: '^a'})                                       ;-- Alles auswählen
cm.mapCombo([5], {release: '^v'})                                          ;-- Einfügen
cm.mapCombo([5, 4], {press: '{alt down}{tab}', pressRelease: '{alt up}'})  ;-- Fenster wechsel init
cm.mapCombo([5, 4, 'WU'], {press: '+{tab}'})                               ;-- Fenster wechsel zurück
cm.mapCombo([5, 4, 'WD'], {press: '{tab}'})                                ;-- Fenster wechsel vor
cm.mapCombo([5, 'WU'], {press: '^y'})                                      ;-- Vorgängig
cm.mapCombo([5, 'WD'], {press: '^z'})                                      ;-- Rückgängig
cm.mapCombo([6, 6], {release: (*) => DllCall('LockWorkStation')})          ;-- Logout
