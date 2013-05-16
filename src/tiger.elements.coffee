Tiger   = @Tiger or require 'tiger'
Element = Tiger.Element


Elements = {}
elements = [
  '2DMatrix'
  # '3DMatrix'
  'ActivityIndicator'
  'AlertDialog'
  'Button'
  # 'ButtonBar'
  # 'CoverFlowView'
  # 'DashboardItem'
  # 'DashboardView'
  'EmailDialog'
  'ImageView'
  'Label'
  'ListItem'
  'ListSection'
  'ListView'
  # 'MaskedImage'
  # 'Notification' # Android
  'OptionDialog'
  'Picker'
  'PickerColumn'
  'PickerRow'
  'ProgressBar'
  'ScrollableView'
  'ScrollView'
  # 'SearchBar'
  'Slider'
  'Switch'
  'Tab'
  'TabGroup'
  # 'TabbedBar'
  'TableView'
  'TableViewRow'
  'TableViewSection'
  'TextArea'
  'TextField'
  # 'Toolbar'
  'View'
  'WebView'
  'Window'
]


## Fix for static analysis during ios compilation.
## To save space in packaged app, comment out unused elements.
## https://gist.github.com/tzmartin/1372475
##
if Ti.Platform.osname isnt "android"
  Ti.UI.create2DMatrix();
  # Ti.UI.create3DMatrix();
  Ti.UI.createActivityIndicator();
  Ti.UI.createAlertDialog();
  Ti.UI.createButton();
  # Ti.UI.createButtonBar();
  # Ti.UI.createCoverFlowView();
  # Ti.UI.createDashboardItem();
  # Ti.UI.createDashboardView();
  Ti.UI.createEmailDialog();
  Ti.UI.createImageView();
  Ti.UI.createLabel();
  Ti.UI.createListItem();
  Ti.UI.createListSection();
  Ti.UI.createListView();
  # Ti.UI.createMaskedImage();
  # Ti.UI.createNotification(); # Android
  Ti.UI.createOptionDialog();
  Ti.UI.createPicker();
  Ti.UI.createPickerColumn();
  Ti.UI.createPickerRow();
  Ti.UI.createProgressBar();
  Ti.UI.createScrollableView();
  Ti.UI.createScrollView();
  # Ti.UI.createSearchBar();
  Ti.UI.createSlider();
  Ti.UI.createSwitch();
  Ti.UI.createTab();
  Ti.UI.createTabGroup();
  # Ti.UI.createTabbedBar();
  Ti.UI.createTableView();
  Ti.UI.createTableViewRow();
  Ti.UI.createTableViewSection();
  Ti.UI.createTextArea();
  Ti.UI.createTextField();
  # Ti.UI.createToolbar();
  Ti.UI.createView();
  Ti.UI.createWebView();
  Ti.UI.createWindow();


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

# Cannot call super outside of instance method.
# Tiger.TableViewRow.extend
#   constructor: (props) ->
#     props = Tiger.extend className: 'GUID' + Spine.guid().slice(-12), props
#     super props


module?.exports = Elements