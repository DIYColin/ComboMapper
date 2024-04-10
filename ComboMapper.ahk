#Requires AutoHotkey v2.0
#SingleInstance

class ComboMapper {
  static DoublePress := 500
  static defaultConf := {press: '', pressRelease: '', release: '', map: false, default: true}
  static initConf := {press: '', pressRelease: '', release: '', map: false, default: false}

  mouseMap := Map()

  comboMap := Map()

  currentMap := {val: this.comboMap, prev: false, next: false}

  lastPressed := ''
  pressed := ''
  count := 1
  
  state := Map()

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

  mapMouse(index, trigger, click := '', release := true){
    this.mouseMap['*' trigger] := {index: index, click: click, release: release}
    this.state[index] := {trigger: trigger, level: false, unset: true}
  }

  mapCombo(trigger, config){
    newconfig := ComboMapper.initConf.Clone()
    for key, val in config.OwnProps() {
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
        Hotkey('*' this.state[current].trigger, this.handle.Bind(this))
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
    static trigger(val){
      Switch(Type(val)){
        Case 'String':
          Send val
        Case 'Func', 'BoundFunc':
          val()
      }
    }

    mouseKey := this.mouseMap[key]

    currentMap := this.currentMap
    loop{
      currentKey := currentMap.val.Get(mouseKey.index, false)
      if(currentKey){
        if(this.lastPressed = mouseKey.index && A_TickCount-this.pressed < ComboMapper.DoublePress){
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

    this.lastPressed := mouseKey.index
    this.pressed := A_TickCount

    if(currentConf.map){
      this.currentMap := this.currentMap.next := currentMap := {val: currentConf.map, prev: this.currentMap, next: false}
    }

    if(currentConf.default){
      if(mouseKey.release){
        Click(mouseKey.click, 'D')
      }else{
        Click(mouseKey.click)
      }
    }

    trigger(currentConf.press)

    if(mouseKey.release){
      KeyWait(this.state[mouseKey.index].trigger)
    }

    trigger(currentConf.pressRelease)

    if(this.lastPressed = mouseKey.index){
      trigger(currentConf.release)
    }

    if(currentConf.default && mouseKey.release){
      Click(mouseKey.click, 'U')
    }
    
    if(currentMap){
      currentMap.prev.next := currentMap.next
      if(currentMap.next){
        currentMap.next.prev := currentMap.prev
      }else{
        this.currentMap := currentMap.prev
      }
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
