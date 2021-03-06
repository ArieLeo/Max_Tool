--strcut cannot put into dictionary (cannot convert to system.obj)
-- structure for presetlist item
--struct preset_struct (Meshlist=#(), Savepath="",Filename="")
-- dictionary for presetlist 
global preset_dic=dotNetObject "System.Collections.Hashtable"
--dictionary for prefix management
global prefix_dic=dotNetObject "System.Collections.HashTable"
--default export path
global defaultpath=pathConfig.getProjectSubDirectory 3
global defaultunit=5
global presetholder=getNodeByName "PresetHolder"
global selectionsets_item=#("None")
global namespace_item=#("None")
global preset_item=#("None")
global objlist=#() 
global FBXrollout

--print presetfolder
function createdummy=(
	presetholder=getNodeByName "PresetHolder"
	if presetholder==undefined then(
		presetholder=Dummy pos: [0,0,0] name:"PresetHolder" scale:[5,5,5]
		--hide and freeze the PresetHolder
		hide presetholder
		freeze presetholder
		--write data to dummy String
		Preset_block = attributes presetData(
			Parameters main rollout:params(
				--define the new attributes to the string
				Preset_Handle Type: #string UI:PresetXML Default:"<PresetXML></PresetXML>"
			)
			Rollout Params "Custom Attributes"(
				--define the UI interface
				editText PresetXML "" Align: #Center readOnly: true 
			)
		)
		CustAttributes.add presetholder Preset_block
	)
)

function loadDatafromXML=(
	--reset dictionay and read data from current dummy
	--initialize data and initialize presetlist
	preset_item=#("None")
	preset_dic.clear()
	--read data
	strxml=presetholder.Preset_Handle
	--print strxml
	xmlDoc = dotNetObject "System.Xml.XmlDocument"
	--load xml file from string store on the scene obj
	xmlDoc.loadXml(strxml)
	docElement = xmlDoc.DocumentElement
	preset_Node=docElement.getElementsByTagName "Preset"
	--go in to each node
	for i=0 to preset_Node.count-1 do(
		tempitem=#()
		preset_Name=(preset_Node.ItemOf(i)).getAttribute "PresetName"
		--update presetlist
		--print preset_Name
		append preset_item preset_Name
		filename_Node=preset_Node.ItemOf[i].getElementsByTagName "FileName"
		--filename_node list have on child only
		file_Name=(filename_Node.ItemOf[0]).getAttribute "FileName"
		savepath_Node=preset_Node.ItemOf[i].getElementsByTagName "SavePath"
		--savepath_node list have on child only
		save_Path=(savepath_Node.ItemOf[0]).getAttribute "SavePath"
		item_Node=(preset_Node.ItemOf[i]).getElementsByTagName "ItemName"
		meshlist=(for i=0 to item_Node.count-1 collect(
			item_Node.ItemOf[i].getAttribute "ItemName"
		))
		append tempitem file_Name
		append tempitem save_Path
		append tempitem meshlist
		preset_dic.Add preset_Name tempitem

		--print preset_dic.item[preset_Name]
	)
	--print preset_item
)


function registercallbacks=(
	callbacks.addScript  #NamedSelSetCreated "FBXrollout.UpdateSelSets()" id:#mycallbacks
	callbacks.addScript  #NamedSelSetDeleted "FBXrollout.UpdateSelSets()" id:#mycallbacks
	callbacks.addScript  #NamedSelSetRenamed "FBXrollout.UpdateSelSets()" id:#mycallbacks
	--selectby scene selection /add callbacks for selectionchange
	callbacks.addScript  #selectionSetChanged "FBXrollout.UpdateSceneSel()" id:#mycallbacks
	--callbacks.show()
	--callbacks.addScript #sceneNodeAdded "addobj()" id:#mycallbacks
)

function removecallbacks=(
	callbacks.removeScripts #NamedSelSetCreated id:#mycallbacks
	callbacks.removeScripts #selectionSetChanged id:#mycallbacks
	--callbacks.removeScripts #sceneNodeAdded id:#mycallbacks
)


--there is no same name object allowed to exist in the scene
function SelectbySelsets index:undefined=(
	objlist=#()
	if index>1 then(
		tempset = selectionsets[index-1]
		select tempset
		for i in 1 to tempset.count do(
			append objlist tempset[i].name
		)
	)
	--select none
	else(
		clearSelection()
		objlist=#()
	)
)

function UpdateNamespaceList=(
	namespace_item=#("None")
	allsceneobj=execute ("$*")
	for obj in allsceneobj do (
		prefixArray = filterString obj.name ":"
		--if prefix exsit
		if prefixArray.count>1 then (
			prefix=""
			for i in 1 to prefixArray.count-1 do (
				prefix= prefix + prefixArray[i]+ ":"
			)
			appendIfUnique namespace_item prefix
		)
	)
)

--there is no same name object allowed to exist in the scene
function SelectbyNamespace index:undefined= (
	objlist=#()
	--clearSelection()
	prefixname=FBXrollout.namespacelist.selected
	if index >1 then (
		prefixobj = execute ("$'"+prefixname+"*'")
		select prefixobj
		for i in 1 to prefixobj.count do(
			append objlist prefixobj[i].name
		)
	)
	else(
		clearSelection()
		objlist=#()
	)
)

function SelectbyPresetlist presetname:undefined=(
	if presetname != "None" then(
		tempitem=preset_dic.item[presetname]
		--unpack item #(filename, savepath, meshlist)
		FBXrollout.fileName.text=tempitem[1]
		defaultpath=tempitem[2]
		FBXrollout.expPathTxt.text=tempitem[2]
		if FBXrollout.presetcheck.checked then (
			objlist=tempitem[3]
			--select objlist 
			clearSelection()
			select_list=#()
			for i in objlist do (
				obj=getNodeByName(i)
				append select_list obj
				--print select_list
			)
			select select_list
		)
	)
	if presetname == "None" and FBXrollout.presetcheck.checked then(
		clearSelection()
		objlist=#()
		FBXrollout.fileName.text=""
		FBXrollout.expPathTxt.text=defaultpath --none can be used as this directory (pathConfig.getProjectSubDirectory 3)
	)
)

function resetcheckstatus checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck=(
	checkbx0.checked=false
	checkbx1.checked=false
	checkbx2.checked=false
	checkbx3.checked=false
)


function saveDataOnXML checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck=(
	fname=getSaveFileName caption:"Save XML File:" types:"XML files (*.xml)|*.xml"
	if fname !=undefined then(
		xmlDoc = dotNetObject "System.Xml.XmlDocument"
		xmlRoot = xmlDoc.CreateElement ("SelectionSets")
		xmlDoc.appendChild xmlRoot
		for i in objlist do (
			ObjNode=xmlDoc.CreateElement "Attribute"
			ObjNode.SetAttribute "ItemName" i
			xmlRoot.appendChild ObjNode
		)
		xmlDoc.save(fname)

	)
)

function readDataOnXML source:undefined=(
	fname=getOpenFileName caption:"Open XML File" types:"XML file(*.xml)|*.xml"
	if fname !=undefined then(
		xmlDoc = dotNetObject "System.Xml.XmlDocument"
		xmlDoc.load(fname)
		docElement=xmlDoc.DocumentElement
		NodeList=docElement.getElementsByTagName "Attribute"
		temp = (for i=0 to (NodeList.count-1) collect (NodeList.item i).getAttribute "ItemName")
		for i in temp do (
			exsits=appendIfUnique source i
			--print exsits
			if exsits==false then (
				messageBox(i+ "exsits")
			)
		)
		return source
	)
)

function UpdatePresetOnXML=(
	-- UpdatePresetOnXML--
	xmlDoc = dotNetObject "System.Xml.XmlDocument"
	xmlRoot = xmlDoc.CreateElement ("PresetXML")
	xmlDoc.appendChild xmlRoot
	it=preset_dic.GetEnumerator()
	while it.MoveNext() do(
		--print it.current.key 
		--print it.current.value
		preset_Node=xmlDoc.CreateElement "Preset"
		preset_Node.SetAttribute "PresetName" it.current.key
		xmlRoot.appendChild preset_node
		filename_Node=xmlDoc.CreateElement "FileName"
		filename_Node.SetAttribute "FileName" it.current.value[1]
		preset_Node.appendChild filename_Node
		savepath_Node=xmlDoc.CreateElement "SavePath"
		savepath_Node.SetAttribute "SavePath" it.current.value[2]
		preset_Node.appendChild savepath_Node
		for i in it.current.value[3] do (
			mesh_Node=xmlDoc.CreateElement "ItemName"
			mesh_Node.SetAttribute "ItemName" i  
			preset_Node.appendChild mesh_Node
		)
	)
	--return string type
	--xmlDoc.save("C:\\Users\\hzwangtenghao\\Desktop\\1\\test2.xml")
	return xmlDoc.OuterXml
)



function AddPresetList source:undefined savepath:undefined filename:undefined preset_name:undefined=(
	if maxFilePath !=undefined then(
		if preset_name.count>0 then(
			exists=appendIfUnique source preset_name
			if exists==false then (
				messageBox("Preset name exists")
				return source
			)
			tempitem=#(filename, savepath, objlist)
			preset_dic.Add preset_name tempitem
			presetholder.Preset_Handle=UpdatePresetOnXML()
			return source
		)
		else(
			messageBox("Preset name cannot be empty")
			return source
		)
	)
	else(
		messageBox("Please save file first")
	)
) 

function RemovePresetList source:undefined selection:undefined selected:undefined=(
	if selected != "None" and selected!= undefined then(
		deleteItem source selection
		--remove pair in preset_dic
		preset_dic.Remove selected
		presetholder.Preset_Handle=UpdatePresetOnXML()
		return source
	)
	else(
		return source
	)
)

function RenamePresetList source:undefined selection:undefined selected:undefined presetname:undefined=(
	if selected !="None" and (findItem source presetname)==0 then(
		--print presetname
		source[selection]=presetname
		--change the key of dic
		preset_dic.Add presetname preset_dic.item[selected]
		preset_dic.Remove selected
		presetholder.Preset_Handle=UpdatePresetOnXML()
		return source

	)
	else(
		messageBox("Preset name exsits")
		return source
	)
	
)

function RemovePrefix  =(
	select_list=#()
	for i in objlist do(
		obj=getNodeByName(i)
		append select_list obj
	)
	select select_list
	--print select_list
	for i in select_list do(
		prefixArray = filterString i.name ":"
		--prefix exist
		if prefixArray.count>1 then(
			prefix=""
			i.name = prefixArray[prefixArray.count]
			for i in 1 to prefixArray.count-1 do (
				prefix=prefix+prefixArray[i]+":"
			)
			--print prefix
			prefix_dic.Add i.name prefix
		)
	)
)

function RecoverPrefix =(
	it=prefix_dic.GetEnumerator()
	while it.MoveNext() do(
		obj=getNodeByName(it.current.key)
		obj.name=it.current.value+obj.name
	)
	prefix_dic.clear()
)

function exportFBX output:undefined meshlist:undefined=(
	if objlist.count>0 then (
		--remove the prefix 
		RemovePrefix()
		-- default export animation
		FbxExporterSetParam "Animation" True
		FbxExporterSetParam "BakeAnimation" True
		FbxExporterSetParam "BakeResampleAnimation" True
		--mesh export options
		FbxExporterSetParam "Skin" True
		FbxExporterSetParam "SmoothingGroups" True
		--use 2011 file version
		FbxExporterSetparam "FileVersion" "FBX201100"
		FbxExporterSetParam "UpAxis" "Y"

		exportFile output #noPrompt selectedOnly:True using:FBXEXP
		--add the prefix back
		RecoverPrefix()
	)
	else(
		messageBox("There is no object selected!")
	)
)

function systemunitsetup index:undefined=(
	case index of (
		1: units.SystemType=#Inches
		2: units.SystemType=#Feet
		3: units.SystemType=#Miles
		4: units.SystemType=#Millimeters
		5: units.SystemType=#Centimeters
		6: units.SystemType=#Meters
		7: units.SystemType=#Kilometers
	)
	defaultunit=index
)

--global FBXrollout

rollout FBXrollout "FBX Exporter" width: 328 height: 640
(
	editText fileName "Filename" pos:[8,12] width:210 height:16
	button copysceneBtn "Copy Scenename" pos:[222,9] width:98 height:24
	label exportPathLabel "Export Path:" pos:[16,40] width:200 height:20 
	editText expPathTxt "" text:defaultpath pos:[8,60] fieldWidth: 206 height:18
	button browseBtn "Browse" pos:[222,56] width:98 height:24
	--selection sets
	GroupBox grpset "Selection" pos:[8,88] width:312 height:190
	checkBox selectionsetscheck "Using Selection Sets:" pos:[16,120] width:132 checked:false
	dropDownlist selectionsetslist pos:[150,117] items:selectionsets_item width: 160 height: 30
	checkBox namespacecheck "Using Name Space:" pos:[16,150] width:132 checked:false
	dropDownlist namespacelist pos:[150,148] items:namespace_item width: 160 height: 30
	--EditText namespaceTxt pos:[148,150] fieldWidth:100 height:10
	--button namespaceBtn "Select" pos:[260,149] width:50 height:20
	CheckBox sceneselectioncheck "Using Scene Selection" pos:[16,180] width:132 checked:true
	CheckBox presetcheck "Using Preset" pos:[16,210] width:132 checked:false
	button exportxmlBtn "Save as XML File" pos:[55,235] width:230 height:25
	--Preset
	dropDownlist presetList "Export Setting Preset:" pos:[16,310] items:#("None") width:200 height:41
	editText presetname "New Presetname" pos:[20,365] width:280 height:15 text: "Put the preset name here..."
	button addpreset "Add" pos: [55,400] width: 88 height: 24 tooltip: "Save above setting to the preset"
	button renamepreset "Rename" pos: [185,400] width:88 height:24 tooltip: "Rename the current preset"
	button removepreset "Remove" pos: [224,326] width: 88 height:24 tooltip: "Remove the current  preset"
	groupBox grpExport "Preset" pos:[8,290] width:312 height:160
	groupBox grpUnitSetup "System Unit Setup:" pos:[8,460] width:312 height:60
	label UnitSetupLabel "1 Unit = 1.0" pos:[60,485] 
	dropDownlist UnitList "" pos:[128,482] width:150 height:41 items:#("Inches","Feet","Miles","Millimeters","Centimeters","Meters","Kilometers")
	groupBox grpTexture "Texture Export" pos:[8,530] width:312 height:140
	checkbox copyTexChk "Copy Texture" pos:[16,550] width:312 height: 16
	radioButtons texOptionRB "Texture Path:" pos:[16,570] width:261 height:56 labels:#("Automatically create path(Export Path/Texture)","Manually configure path") columns:1
	editText texPathTxt "" pos:[16,625] width:216 height:16
	button browseTexPathBtn "Browse" pos:[240,623] width:72 height:20
	--label texSourceLabel "Configure texture "
	button expBtn "Export File" pos:[16,680] width:296 height:30


	function UpdateSelSets =(
	--update list
	selectionsets_item=#("None")
	for i in 1 to selectionSets.count do (
		appendIfUnique selectionsets_item (GetNamedSelSetName i)
		)
	selectionsetslist.items=selectionsets_item
	--print selectionsetslist.items
	)

	function UpdateSceneSel =(
		--print "callbacks"
		if sceneselectioncheck.checked then (
			--update sceneselection
			objlist=#()
			selobj=selection
			if selobj != undefined then(
				for i in 1 to selobj.count do(
					appendIfUnique objlist selobj[i].name
				)
			)
			else(
				objlist=#()
				clearSelection()
			)
			--print objlist
		)
	)

	on FBXrollout open do (
		--set the default unit to centimeter when initialize the gui
		UnitList.selection=defaultunit
		systemunitsetup index:defaultunit 
		selectionsetslist.enabled=false
		namespacelist.enabled=false
		--register callbacks for selectionsets
		registercallbacks()
		--initialize the list for selectionsets
		UpdateSelSets()
		--initialize the objlist for sceneselection
		UpdateSceneSel()
		--update presetList
		presetList.items=preset_item
		--update namespacelist
		--initialize namespacelist
		UpdateNamespaceList()
		namespacelist.items=namespace_item
	)

	on FBXrollout close do (
		--remove callbacks for selectionsets
		removecallbacks()
	)

	on selectionsetscheck changed status do(
		resetcheckstatus checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck 
		selectionsetscheck.checked=true
		selectionsetscheck.enabled=true
		selectionsetslist.enabled=true
		--update current selectionSets
		SelectbySelsets index: selectionsetslist.selection
		--reset namespacelist to none
		namespacelist.enabled=false
		namespacelist.selection=1

	)


	on selectionsetslist selected index do (
		SelectbySelsets index:index
	)

	on namespacelist selected index do (
		SelectbyNamespace index:index
	)

	on namespacecheck changed status do(
		resetcheckstatus checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck 
		namespacecheck.checked=true
		namespacecheck.enabled=true
		namespacelist.enabled=true
		--update current namespace
		SelectbyNamespace index:namespacelist.selection
		--reset selectionsetlist to none
		selectionsetslist.enabled=false
		selectionsetslist.selection=1
	)


	on sceneselectioncheck changed status do (
		resetcheckstatus checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck 
		sceneselectioncheck.checked=true
		sceneselectioncheck.enabled=true
		selectionsetslist.enabled=false
		--reset selectionsetlist to none
		selectionsetslist.enabled=false
		selectionsetslist.selection=1
		--reset namespacelist to none
		namespacelist.enabled=false
		namespacelist.selection=1
		--update scene selection
		UpdateSceneSel()
	)
	on presetcheck changed status do(
		resetcheckstatus checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck 
		presetcheck.checked=true
		presetcheck.enabled=true
		--reset selectionsetlist to none
		selectionsetslist.enabled=false
		selectionsetslist.selection=1
		--reset namespacelist to none
		namespacelist.enabled=false
		namespacelist.selection=1
		--update Preset
		SelectbyPresetlist presetname:presetlist.selected
	)
	on exportxmlBtn pressed do (
		saveDataOnXML checkbx0: selectionsetscheck checkbx1: namespacecheck checkbx2: sceneselectioncheck checkbx3:presetcheck
	)

	on copysceneBtn pressed do(
		scenename = getFilenameFile maxFileName
		--print scenename
		filename.text=scenename
	)

	on browseBtn pressed do(
		p=getSavePath caption:"Defined Output Path" initialDir:expPathTxt.text
			if p!=undefined then (
				expPathTxt.text=p
				defaultpath=p
			)
	)

	on addpreset pressed do (
		presetList.items=AddPresetList source: presetList.items savepath:expPathTxt.text filename:fileName.text preset_name:presetname.text
	)

	on presetList selected index do(
		SelectbyPresetlist presetname:presetlist.selected
	)

	on Removepreset pressed do (
		presetlist.items=RemovePresetList source: presetlist.items selection:presetlist.selection selected: presetlist.selected
	)

	on Renamepreset pressed do (
		presetlist.items=RenamePresetList source:presetlist.items selection:presetlist.selection selected:presetlist.selected presetname:presetname.text

	)
	on expBtn pressed do (
		outputpath= expPathTxt.text + "\\" + filename.text
		--print outputpath
		exportFBX output: outputpath
	)

	on UnitList selected index do(
		systemunitsetup index:index
	)

)


utility LT_FBX_Exporter "LT_FBX_Exporter"
(
	local expFloater

	button expBtn "FBX_Exporter" width:120;
	
	on expBtn pressed do (
		-- if the floater is open close it and reopen a new one 
		try (closeRolloutFloater expFloater) catch()
		createdummy()
		loadDatafromXML()
		expFloater=newRolloutFloater "FbxExporter" 336 700
		addRollout FBXrollout expFloater
	)
	

)