#Requires AutoHotkey v2.0

class ComboMapper {
  mouseMap := Map()

  comboMap := Map()

  currentMap := [this.comboMap]

  lastPressed = ''
  
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
    this.mouseMap[trigger] := {index: index, click: click?, release: release}
    this.state[index] := {trigger: trigger, press: 0, release: 0, level: false}
  }

  mapCombo(trigger, config){
    current := trigger[1]
    currentMap := this.comboMap
    currentKey := 0
    count := 0
    loop(trigger.Length){
      if(this.unsetHotkeys.Has(current)){
        Hotkey(this.unsetHotkeys.Delete(current), this.handle.Bind(this))
      }
      if(this.state)
      if(current != trigger[A_Index]){
        currentMap := Map()
        currentKey[count].map := currentMap
        current := trigger[A_Index]
        count := 1
        Hotkey(this.revMouseMap[current], this.handle.Bind(this))
      }
      if(currentMap.Has(trigger[A_Index])){
        currentKey := currentMap[trigger[A_Index]]
      }else{
        currentKey := []
        currentMap[trigger[A_Index]] := currentKey
      }
      if(current = trigger[A_Index]){
        ++count
      }
      if(count > currentKey.Length){
        if(A_Index = trigger.Length){
          currentKey.Push(config)
        }else{
          currentKey.Push({})
        }
      }
    }
  }

  handle(key){
    mouseKey := this.mouseMap[key]
    if(mouseKey.index){
      level := this.currentMap.Length
      loop{
        currentConf := this.currentMap[level].Get(mouseKey.index, false)
      }until(--level = 0 || currentConf)
    }
    if(mouseKey.click){
      if(mouseKey.release){
        Click(mouseKey.click, 'D')
      }else{
        Click(mouseKey.click)
      }
    }
    if(mouseKey.release){
      KeyWait(key)
    }
    if(mouseKey.release && mouseKey.click){
      Click(mouseKey.click, 'U')
    }
  }
}

cm := ComboMapper()
cm.mapMouse(6, 'F24')
cm.mapCombo([4], {release: '^c'})