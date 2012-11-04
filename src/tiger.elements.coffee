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
  open: ->
    @element.open()
    @

  close: ->
    @element.close()
    @


Tiger.OptionDialog.include
  show: ->
    @element.show()
    @

  hide: ->
    @element.hide()
    @


Tiger.TableView.include
  appendRow: (el) ->
    @element.appendRow(el.element or el)
    @
  setData: (rows) ->
    nativeRows = (row.element or row for row in rows)
    @element.setData nativeRows
    @
  setSections: (sections) ->
    @element.appendSection (section.element or section) for section in sections
    @

Tiger.TableViewRow.extend
  constructor: (props) ->
    props = Tiger.extend className: 'GUID' + Spine.guid().slice(-12), props
    super props


module?.exports = Elements