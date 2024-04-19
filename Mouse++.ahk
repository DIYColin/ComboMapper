#Requires AutoHotkey v2.0
#SingleInstance
A_HotkeyInterval := 2000
A_MaxHotkeysPerInterval := 200
A_IconTip := 'Mouse++'

class MousePlusPlus {
  static DoublePress := 500
  static actionHooks := Map('press', true, 'pressRelease', true, 'release', true)
  static defaultConf := {desc: '', press: false, pressRelease: false, release: false, map: false, default: true}
  static initConf := {desc: '', press: false, pressRelease: false, release: false, map: false, default: false}

  static setupAction(val){
    Switch(Type(val)){
      Case 'String':
        return (*) => Send(val)
      Case 'Func', 'BoundFunc':
        return val
    }
  }

  class ActionSwitch{
    enabled := false
    actions := Map(
      true, false,
      false, false
    )

    __New(config){
      for key, val in config.OwnProps() {
        val := MousePlusPlus.setupAction(val)
        Switch key {
          Case 'enable':
            this.actions[true] := val
          Case 'disable':
            this.actions[false] := val
        }
      }
    }

    Call(enabled := !this.enabled){
      if(enabled != this.enabled){
        this.enabled := enabled
        if(this.actions[enabled]){
          this.actions[enabled]()
        }
        return true
      }
      return false
    }
  }

  mouseMap := Map()

  comboMap := Map()

  customMaps := Map()

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

    A_TrayMenu.Delete()
    A_TrayMenu.Add('Show Mappings', (*) => this.showMappings)
    A_TrayMenu.Default := 'Show Mappings'
    A_TrayMenu.ClickCount := 1
  }

  showMappings(){
    MappingGui := Gui()
    TV := MappingGui.Add("TreeView")
    P1 := TV.Add("First parent")
    MappingGui.Show
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

  mapCombo(trigger, config, currentMap := this.comboMap){

    newconfig := MousePlusPlus.initConf.Clone()
    for key, val in config.OwnProps() {
      if(MousePlusPlus.actionHooks.Has(key)){
        val := MousePlusPlus.setupAction(val)
      }
      newconfig.DefineProp(key, {value: val})
    }
    current := trigger[1]
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
          currentKey.Push(MousePlusPlus.defaultConf.Clone())
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
          if(this.lastPressed = mouseKey && A_TickCount - this.pressed < MousePlusPlus.DoublePress){
            this.count := Mod(this.count, currentKey.Length) + 1
          }else{
            this.count := 1
          }
          currentConf := currentKey[this.count]
          currentMap := false
          break
        }
        if(!(currentMap := currentMap.prev)){
          currentConf := MousePlusPlus.defaultConf
          break
        }
      }
  
      state.config := currentConf
  
      this.lastPressed := mouseKey
      this.pressed := A_TickCount
  
      if(currentConf.map){
        this.currentMap := this.currentMap.next := state.map := {val: currentConf.map, prev: this.currentMap, next: false}
      }
  
      if(currentConf.press){
        currentConf.press()
      }
  
      if(currentConf.default && state.bpress){
        state.bpress()
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
      if(this.lastPressed = mouseKey && currentConf.release){
        currentConf.release()
      }

      if(currentConf.default && state.brelease){
        state.brelease()
      }

      if(currentConf.pressRelease){
        currentConf.pressRelease()
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

  setMap(customMap){
    customMapItem := this.customMaps.Get(customMap, false)
    if(customMapItem){
      if(this.currentMap = customMapItem){
        return
      }
      this.unsetMap(customMap)
    }else{
      this.currentMap := this.currentMap.next := this.customMaps[customMap] := {val: customMap, prev: this.currentMap, next: false}
    }
  }

  unsetMap(customMap){
    customMapItem := this.customMaps.Get(customMap, false)
    if(customMapItem){
      customMapItem.prev.next := customMapItem.next
      if(customMapItem.next){
        customMapItem.next.prev := customMapItem.prev
      }else{
        this.currentMap := customMapItem.prev
      }
      this.customMaps.Delete(customMap)
    }
  }
}

initTabSwitch := MousePlusPlus.ActionSwitch({
  enable: '{ctrl down}',
  disable: '{ctrl up}'
})

initSearchSwitch := MousePlusPlus.ActionSwitch({
  enable: '^f'
})

mpp := MousePlusPlus()
mpp.mapMouse(6, 'F24')
mpp.mapCombo([1, 4],          {desc: 'Drag and Drop Datei kopieren, FancyZones select multiple', press: '{ctrl down}', pressRelease: '{ctrl up}'})                    
mpp.mapCombo([1, 5],          {desc: 'Drag and Drop Datei verschieben', press: '{shift down}', pressRelease: '{shift up}'})                  
mpp.mapCombo([3],             {desc: 'init Tab wechsel', pressRelease: (*) => initTabSwitch(false), default: true})              
mpp.mapCombo([3, 'WU'],       {desc: 'Tab zurück', press: (*) => (                                                   
  initTabSwitch(true),
  Send('+{tab}')
)})
mpp.mapCombo([3, 'WD'],       {desc: 'Tab vor', press: (*) => (                                                   
  initTabSwitch(true),
  Send('{tab}')
)})
mpp.mapCombo([3, 2],          {desc: 'Entwicklertools öffnen', release: '^+i'})                                                     
mpp.mapCombo([3, 3],          {desc: 'Tab schließen', release: '^w'})                                                      
mpp.mapCombo([3, 4],          {desc: 'Tab öffnen', release: '^t'})                                                      
mpp.mapCombo([3, 4, 5],       {desc: 'Geschlossenen Tab öffnen', release: '^+t'})                                                  
mpp.mapCombo([3, 5],          {desc: 'Fenster öffnen', release: '^n'})                                                      
mpp.mapCombo([3, 5, 4],       {desc: 'Incognito Fenster öffnen', release: '^+n'})                                                  
mpp.mapCombo([4],             {desc: 'Kopieren', release: '^c'})                                                         
mpp.mapCombo([4, 1],          {desc: 'Drag and Drop Datei kopieren, FancyZones select multiple', press: '{ctrl down}', pressRelease: '{ctrl up}', default: true})     
mpp.mapCombo([4, 3],          {desc: 'Fenster wechsel init', press: '{alt down}{tab}', pressRelease: '{alt up}'})                 
mpp.mapCombo([4, 3, 'WU'],    {desc: 'Fenster wechsel zurück', press: '+{tab}'})                                              
mpp.mapCombo([4, 3, 'WD'],    {desc: 'Fenster wechsel vor', press: '{tab}'})                                               
mpp.mapCombo([4, 5],          {desc: 'Ausschneiden', pressRelease: (*) => initSearchSwitch(false), release: '^x'})        
mpp.mapCombo([4, 5, 'WU'],    {desc: 'Suchen zurück', press: (*) => (                                                
  initSearchSwitch(true) || Send('+{F3}')
)})
mpp.mapCombo([4, 5, 'WD'],    {desc: 'Suchen weiter', press: (*) => (                                                
  initSearchSwitch(true) || Send('{F3}')
)})
mpp.mapCombo([4, 6],          {desc: 'Alles auswählen und kopieren', release: '{ctrl down}ac{ctrl up}'})                                  
mpp.mapCombo([5],             {desc: 'Einfügen', release: '^v'})                                                         
mpp.mapCombo([5, 1],          {desc: 'Drag and Drop Datei verschieben', press: '{shift down}', pressRelease: '{shift up}', default: true})   
mpp.mapCombo([5, 3],          {desc: 'neuer Virtueller Desktop', release: '^#d'})                                                     
mpp.mapCombo([5, 3, 'WU'],    {desc: 'vorheriger Virtueller Desktop', press: '^#{left}'})                                            
mpp.mapCombo([5, 3, 'WD'],    {desc: 'nächster Virtueller Desktop', press: '^#{right}'})                                           
mpp.mapCombo([5, 3, 4],       {desc: 'schließe Virtueller Desktop', release: '^#{F4}'})                                               
mpp.mapCombo([5, 3, 4, 'WU'], {desc: 'vorheriger Virtueller Desktop Fenster mitnehmen', press: (*) => (                                             
  Title := WinGetTitle('A'),
  WinSetExStyle('^0x80', Title),
  Send('^#{left}'),
  sleep(50),
  WinSetExStyle('^0x80', Title),
  WinActivate(Title)
)})
mpp.mapCombo([5, 3, 4, 'WD'], {desc: 'nächster Virtueller Desktop Fenster mitnehmen', press: (*) => (                              
  Title := WinGetTitle('A'),
  WinSetExStyle('^0x80', Title),
  Send('^#{right}'),
  sleep(50),
  WinSetExStyle('^0x80', Title),
  WinActivate(Title)
)})
mpp.mapCombo([5, 4],       {desc: 'Rückgängig', press: '^z'})                                         
mpp.mapCombo([5, 4, 'WU'], {desc: 'Vorgängig', press: '^y'})                                   
mpp.mapCombo([5, 4, 'WD'], {desc: 'Rückgängig', press: '^z'})                                   
mpp.mapCombo([6],          {desc: 'Play/Pause', release: '{Media_Play_Pause}'})                          
mpp.mapCombo([6, 4],       {desc: 'Next', release: '{Media_Next}'})                             
mpp.mapCombo([6, 5],       {desc: 'Prev', release: '{Media_Prev}'})                             
mpp.mapCombo([6, 6],       {desc: 'Maximize Toggle', release: '#{up}'})                                    
mpp.mapCombo([6, 6, 4],    {desc: 'Left', release: '#{left}'})                               
mpp.mapCombo([6, 6, 5],    {desc: 'Right', release: '#{right}'})                              
mpp.mapCombo([6, 6, 6],    {desc: 'Logout', release: (*) => DllCall('LockWorkStation')})       
