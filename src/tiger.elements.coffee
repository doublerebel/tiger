Tiger   = @Tiger or require 'tiger'
Element = Tiger.Element


Elements = {}
elements = [
  'ActivityIndicator'
  'AlertDialog'
  'Button'
  # 'DashboardItem'
  # 'DashboardView'
  'EmailDialog'
  'ImageView'
  'Label'
  'OptionDialog'
  # 'Picker'
  # 'PickerColumn'
  # 'PickerRow'
  # 'ProgressBar'
  # 'ScrollableView'
  'ScrollView'
  # 'SearchBar'
  'Slider'
  'Switch'
  # 'Tab'
  # 'TabGroup'
  'TableView'
  'TableViewRow'
  'TableViewSection'
  # 'TextArea'
  'TextField'
  'View'
  'WebView'
  'Window'
]

for element in elements
  class Elements[element] extends Element
    elementName: element
    
Tiger[element] = Elements[element] for element in elements


# Extend individual elements for special cases
Tiger.Window.include
  open: -> @element.open()
  close: -> @element.close()
  # constructor: (props) ->
  #   props = Tiger.extend @defaults or {}, props
  #   win = @element = Ti.UI['create' + @elementName](props)
    
  #   @tiBind 'android:back', ->
  #     for child of win.children
  #       win.remove child
  #     setTimeout (-> win.close()), 10

Tiger.TableView.include
  appendRow: (el) ->
    @element.appendRow(el.element || el)
    @
  setData: (rows) ->
    nativeRows = []
    for row in rows
      nativeRows.push(row.element || row)
    @element.setData nativeRows
    @

Tiger.TableViewRow.extend
  constructor: (props) ->
    props = Tiger.extend className: 'GUID' + Spine.guid().slice(-12), props
    super props


module?.exports = Elements