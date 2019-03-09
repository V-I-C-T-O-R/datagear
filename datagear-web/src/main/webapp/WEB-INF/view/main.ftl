<#include "include/import_global.ftl">
<#include "include/html_doctype.ftl">
<html>
<head>
<#include "include/html_head.ftl">
<title><@spring.message code='app.name' /></title>
<#include "include/page_js_obj.ftl" >
<script type="text/javascript">
(function(po)
{
	po.userId = "${currentUser.id?js_string}";
	po.isAnonymous = ${currentUser.anonymous?c};
	po.isAdmin = ${currentUser.admin?c};
	
	po.workTabTemplate = "<li style='vertical-align:middle;'><a href='"+'#'+"{href}'>"+'#'+"{label}</a>"
			+"<div class='tab-operation'>"			
			+"<span class='ui-icon ui-icon-close' title='<@spring.message code='close' />'>close</span>"
			+"<div class='tab-operation-more' title='<@spring.message code='moreOperation' />'></div>"
			+"</div>"
			+"<div class='category-bar category-bar-"+'#'+"{schemaId}'></div>"
			+"</li>";
	
	po.activeWorkTab = function(tabId, tabLabel, tabTitle, schema, url, tabType)
	{
		tabLabel = $.truncateIf(tabLabel, "..", 20);
		
		var schemaId = schema.id;
		
		var mainTabs = po.element("#mainTabs");
		var uiTabsNav = mainTabs.find(".ui-tabs-nav");
		
	    var prelia = $("> li > a[href='#"+tabId+"']", uiTabsNav);
	    if(prelia.length > 0)
	    {
	    	var myidx = prelia.parent().index();
	    	mainTabs.tabs("option", "active",  myidx);
	    }
	    else
	    {
	    	var tooltipId = $.tipInfo("<@spring.message code='loading' />", -1);
	    	$.ajax(
			{
				url : url, 
	    		success:function(data)
		    	{
		    		uiTabsNav.show();
		    		
		    		var li = $("> li > a[href='#"+tabId+"']", uiTabsNav);
		    		var tabContentDiv = $("#"+tabId, mainTabs);
		    		
		    		//防止双击导致创建两次而引起界面错乱
		    		if(li.length == 0)
		    		{
		    			li = $(po.workTabTemplate.replace( /#\{href\}/g, "#" + tabId).replace(/#\{label\}/g, tabLabel).replace(/#\{schemaId\}/g, schemaId)).appendTo(uiTabsNav);
		    			
		    			if(!li.attr("id"))
		    				li.attr("id", $.uid("main-tab-"));
		    			
		    			li.attr("schema-id", schemaId);
		    			li.attr("tab-url", url);
		    			li.attr("title", tabTitle);
		    			li.attr("tab-type", tabType);
		    		}
		    		
		    	    if(tabContentDiv.length == 0)
		    	    	tabContentDiv = $("<div id='" + tabId + "'></div>").appendTo(mainTabs);
		    	    
		    	    mainTabs.tabs("refresh").tabs( "option", "active",  $("> li", uiTabsNav).length - 1);
		    	    
		    	    tabContentDiv.css("top", po.evalTabPanelTop(mainTabs));
		    	    tabContentDiv.html(data);
		    	    
		    	    $(".tab-operation .ui-icon-close", li).click(function()
		    	    {
		    	    	var li = $(this).parent().parent();
		    	    	var tabId = $("a", li).attr("href");
		    	    	
		    	    	$(tabId, mainTabs).remove();
		    	    	li.remove();
		    	    	
		    	    	mainTabs.tabs("refresh");
		    	    	po.refreshTabsNav(mainTabs);
		    	    	 
		 				if($("li", uiTabsNav).length == 0)
		 					uiTabsNav.hide();
		    	    });
		    	    
		    	    $(".tab-operation .tab-operation-more", li).click(function()
		    	    {
		    	    	var li = $(this).parent().parent();
		    	    	var tabId = $("a", li).attr("href");
		    	    	
		    	    	po.element("#tabMoreOperationMenuParent").show().css("left", "0px").css("top", "0px")
		    	    		.position({"my" : "left top+1", "at": "right bottom", "of" : $(this), "collision": "flip flip"});
	
		    	    	var menuItemDisabled = {};
		    	    	
		    	    	var hasPrev = (li.prev().length > 0);
		    	    	var hasNext = (li.next().length > 0);
		    	    	
		    	    	menuItemDisabled[".tab-operation-close-left"] = !hasPrev;
		    	    	menuItemDisabled[".tab-operation-close-right"] = !hasNext;
		    	    	menuItemDisabled[".tab-operation-close-other"] = !hasPrev && !hasNext;
		    	    	
		    	    	var menu = po.element("#tabMoreOperationMenu");
		    	    	
		    	    	for(var selector in menuItemDisabled)
		    	    	{
		    	    		if(menuItemDisabled[selector])
		    	    			$(selector, menu).addClass("ui-state-disabled");
		    	    		else
		    	    			$(selector, menu).removeClass("ui-state-disabled");
		    	    	}
		    	    	
		    	    	menu.attr("tab-id", tabId)
		    	    		.attr("schema-id", li.attr("schema-id")).attr("tab-url", li.attr("tab-url"));
		    	    });
    			},
	        	complete : function()
	        	{
	        		$.closeTip(tooltipId);
	        	}
			});
	    }
	};
	
	po.genTabId = function(schemaId, tableName)
	{
		var map = (po.genTabIdMap || (po.genTabIdMap = {}));
		
		//不能直接使用这个key作为元素ID，因为tableName中可能存在与jquery冲突的字符，比如'$'
		var key = schemaId +"_" + tableName;
		var value = map[key];
		
		if(value == undefined)
		{
			var nextNumber = (po.genTabIdNextNumber != undefined 
					? (po.genTabIdNextNumber = po.genTabIdNextNumber + 1) : (po.genTabIdNextNumber = 0));
			
			value = "mainTabs-" + nextNumber;
			map[key] = value;
		}
		
		return value;
	};

	po.isSchemaNode = function(node)
	{
		if(!node)
			return false;
		
		var original = node.original;
		
		if(!original)
			return false;
		
		return (original.id != undefined && original.url != undefined);
	};
	
	po.schemaToJstreeNode = function(schema)
	{
		schema.text = $.escapeHtml(schema.title);
		
		var tempSchema = (schema.createUser && schema.createUser.anonymous);
		
		if(tempSchema)
			schema.text += " <span class='ui-icon ui-icon-notice' title='<@spring.message code='main.tempSchema' />'></span>";
		else
		{
			if(schema.createUser && po.userId != schema.createUser.id && schema.createUser.nameLabel)
				schema.text += " <span class='schema-tree-create-user-label small-text ui-state-disabled' title='<@spring.message code='main.schemaCreateUser' />'>" + $.escapeHtml(schema.createUser.nameLabel) + "</span>";
		}
		
		schema.children = true;
		
		return schema;
	};
	
	po.schemaToJstreeNodes = function(schemas)
	{
		for(var i=0; i<schemas.length; i++)
			po.schemaToJstreeNode(schemas[i]);
		
		return schemas;
	};

	po.isTableNode = function(node)
	{
		var original = node.original;
		
		return (original.name != undefined && original.type != undefined);
	};
	
	po.isTableView = function(tableInfo)
	{
		return (tableInfo.type == "VIEW");
	};
	
	po.tableToJstreeNode = function(table)
	{
		var text = table.name;
		
		table.text = $.escapeHtml(text);
		table.children = false;
		
		var licss = (po.isTableView(table) ? "view-node" : "table-node");
		table.li_attr = { "class" : licss };
		
		var atitle = (po.isTableView(table) ? "<@spring.message code='main.tableType.view' />" : "<@spring.message code='main.tableType.table' />")
					+"<@spring.message code='colon' />" + table.name;
		if(table.comment)
			atitle += "<@spring.message code='bracketLeft' />" + table.comment + "<@spring.message code='bracketRight' />";
		
		table.a_attr = { "title" :  atitle};
		
		return table;
	};
	
	po.tableToJstreeNodes = function(tables)
	{
		for(var i=0; i<tables.length; i++)
			po.tableToJstreeNode(tables[i]);
		
		return tables;
	};
	
	po.createNextPageNode = function(pagingData)
	{
		var showCount = (pagingData.page > 0 ? pagingData.page-1 : 0) * pagingData.pageSize
							+ (pagingData.items ? pagingData.items.length : 0);
		
		var nextPageNode =
		{
			"text" : "<span class='more-table'><#assign messageArgs=['"+showCount+"','"+pagingData.total+"']><@spring.messageArgs code='main.moreTable' args=messageArgs /></span>",
			"children" : false,
			"li_attr" : { "class" : "next-page-node" },
			"nextPageInfo" :
			{
				"page" : pagingData.page + 1,
				"pageSize" : pagingData.pageSize
			}
		};
		
		return nextPageNode;
	};
	
	po.isNextPageNode = function(node)
	{
		var original = node.original;
		
		return (original.nextPageInfo != undefined);
	};

	po.toJstreeNodePagingData = function(pagingData)
	{
		po.tableToJstreeNodes(pagingData.items);
		
		//添加下一页节点
		if(pagingData.page < pagingData.pages)
		{
			var nextPageNode = po.createNextPageNode(pagingData);
			
			pagingData.items.push(nextPageNode);
		}

		//jstree的_append_json_data方法有“if(data.d){data = data.d;...}”的逻辑，可以用来适配数据
		pagingData.d = pagingData.items;
	};

	po.isSearchTable = function()
	{
		var $icon = po.element("#schemaSearchSwitch > .ui-icon");
		
		return $icon.hasClass("ui-icon-document");
	};
	
	po.getSearchSchemaFormData = function()
	{
		var form = po.element("#schemaSearchForm");
		var keyword = $("input[name='keyword']", form).val();
		var pageSize = $("input[name='pageSize']", form).val();
		return {"keyword" : keyword, "pageSize" : pageSize};
	};
	
	po.getSearchSchemaFormDataForSchema = function()
	{
		if(po.isSearchTable())
			return {};
		else
			return po.getSearchSchemaFormData();
	};
	
	po.getSearchSchemaFormDataForTable = function()
	{
		var data = po.getSearchSchemaFormData();
		
		if(!po.isSearchTable())
			data["keyword"] = "";
		
		return data;
	};
	
	po.evalTabPanelTop = function($tab)
	{
		var $nav = $("> ul", $tab);
		
		var top = 0;
		
		top += parseInt($tab.css("padding-top"));
		top += parseInt($nav.css("margin-top")) + parseInt($nav.css("margin-bottom")) + $nav.outerHeight() + 5;
		
		return top;
	};
	
	po.refreshSchemaTree = function()
	{
		var $tree = po.element(".schema-panel-content");
		$tree.jstree(true).refresh(true);
	};
	
	$(document).ready(function()
	{
		var westMinSize = po.element(".schema-panel-head").css("min-width");
		
		if(westMinSize)
		{
			var pxIndex = westMinSize.indexOf("px");
			if(pxIndex > -1)
				westMinSize = westMinSize.substring(0, pxIndex);
		}
		
		westMinSize = parseInt(westMinSize);
		
		if(isNaN(westMinSize) || westMinSize < 245)
			westMinSize = 245;
		
		po.element(".main-page-content").layout(
		{
			west :
			{
				size : "18%",
				minSize : westMinSize
			},
			onresize_end : function(){ $(window).resize();/*触发page_obj_grid.jsp表格resize*/ }
		});
		
		po.element("#systemSetMenu").menu(
		{
			position : {my:"right top", at: "right bottom-1"},
			select : function(event, ui)
			{
				var $item = $(ui.item);
				
				if($item.hasClass("ui-state-disabled"))
					return;
				
				if($item.hasClass("system-set-global-setting"))
				{
					po.open(contextPath+"/globalSetting");
				}
				else if($item.hasClass("system-set-schema-url-builder"))
				{
					po.open(contextPath+"/schemaUrlBuilder/editScriptCode");
				}
				else if($item.hasClass("system-set-driverEntity-add"))
				{
					po.open(contextPath+"/driverEntity/add");
				}
				else if($item.hasClass("system-set-driverEntity-manage"))
				{
					var options = {};
					$.setGridPageHeightOption(options);
					po.open(contextPath+"/driverEntity/query", options);
				}
				else  if($item.hasClass("system-set-user-add"))
				{
					po.open(contextPath+"/user/add");
				}
				else if($item.hasClass("system-set-user-manage"))
				{
					var options = {};
					$.setGridPageHeightOption(options);
					po.open(contextPath+"/user/query", options);
				}
				else if($item.hasClass("system-set-personal-set"))
				{
					po.open(contextPath+"/user/personalSet");
				}
				else if($item.hasClass("theme-item"))
				{
					var theme = $item.attr("theme");
					
					$.getJSON(contextPath+"/changeThemeData?theme="+theme, function(data)
					{
						for(var i=0; i<data.length; i++)
							$(data[i].selector).attr(data[i].attr, data[i].value);
					});
				}
				else if($item.hasClass("about"))
				{
					po.open(contextPath+"/about", { width : "50%" });
				}
				else if($item.hasClass("documentation"))
				{
					window.open("http://www.datagear.tech/documentation/");
				}
				else if($item.hasClass("changelog"))
				{
					po.open(contextPath+"/changelog");
				}
			}
		});

		po.element("#schemaSearchSwitch").click(function()
		{
			var $icon = $(".ui-icon", this);
			
			if($icon.hasClass("ui-icon-document"))
				$icon.removeClass("ui-icon-document").addClass("ui-icon-folder-collapsed").attr("title", "<@spring.message code='main.searchSchema' />");
			else
				$icon.removeClass("ui-icon-folder-collapsed").addClass("ui-icon-document").attr("title", "<@spring.message code='main.searchTable' />");
		});
		
		po.element("#schemaOperationMenu").menu(
		{
			position : {my:"right top", at: "right bottom-1"},
			focus : function(event, ui)
			{
				var $item = $(ui.item);
				
				if($item.hasClass("schema-operation-root"))
				{
					var menuItemEnables =
					{
						"schema-operation-edit" : true,
						"schema-operation-delete" : true,
						"schema-operation-view" : true,
						"schema-operation-refresh" : true,
						"schema-operation-reload" : true,
						"schema-operation-sqlpad" : true
					};
					
					var jstree = po.element(".schema-panel-content").jstree(true);
					var selNodes = jstree.get_selected(true);
					
					var disableCRUD = false;
					
					//未选中数据库，则禁用CRUD按钮
					if(!selNodes.length)
					{
						disableCRUD = true;
						menuItemEnables["schema-operation-sqlpad"] = false;
					}
					else
					{
						for(var i=0; i<selNodes.length; i++)
						{
							if(!po.isSchemaNode(selNodes[i]))
							{
								disableCRUD = true;
								break;
							}
						}
					}
					
					if(disableCRUD)
					{
						menuItemEnables["schema-operation-edit"] = false;
						menuItemEnables["schema-operation-delete"] = false;
						menuItemEnables["schema-operation-view"] = false;
					}
					
					var diableEditAndDelete = false;
					
					//管理员、创建用户才能编辑和删除数据库
					for(var i=0; i<selNodes.length; i++)
					{
						if(!po.isSchemaNode(selNodes[i]))
						{
							diableEditAndDelete = true;
							break;
						}
						
						var schema = selNodes[i].original;
						
						if(!po.isAdmin && schema.createUser != undefined && schema.createUser.id != po.userId)
						{
							diableEditAndDelete = true;
							break;
						}
					}
					
					if(diableEditAndDelete)
					{
						menuItemEnables["schema-operation-edit"] = false;
						menuItemEnables["schema-operation-delete"] = false;
					}
					
					//如果有选中，且全都是数据库或者全都是表，则启用刷新按钮
					menuItemEnables["schema-operation-refresh"] = false;
					if(selNodes.length)
					{
						var selSchemaCount = 0, selTableCount = 0;
						for(var i=0; i<selNodes.length; i++)
						{
							if(po.isTableNode(selNodes[i]))
							{
								selTableCount++;
							}
							else if(po.isSchemaNode(selNodes[i]))
							{
								selSchemaCount++;
							}
						}
						
						if(selSchemaCount == 0 || selTableCount == 0)
							menuItemEnables["schema-operation-refresh"] = true;
					}
					
					//只要选中了表，就禁用重载按钮
					for(var i=0; i<selNodes.length; i++)
					{
						if(po.isTableNode(selNodes[i]))
						{
							menuItemEnables["schema-operation-reload"] = false;
							break;
						}
					}
					
					var $menu = $(this);
					
					for(var itemClass in menuItemEnables)
					{
						if(menuItemEnables[itemClass])
							$("." + itemClass, this).removeClass("ui-state-disabled");
						else
							$("." + itemClass, this).addClass("ui-state-disabled");
					}
				}
			},
			select : function(event, ui)
			{
				var $item = $(ui.item);
				
				if($item.hasClass("ui-state-disabled"))
					return;
				
				var jstree = po.element(".schema-panel-content").jstree(true);
				var selNodes = jstree.get_selected(true);
				
				if($item.hasClass("schema-operation-edit") || $item.hasClass("schema-operation-view"))
				{
					if(selNodes.length != 1)
					{
						$.tipInfo("<@spring.message code='pleaseSelectOnlyOneRow' />");
						return;
					}
					
					var selNode = selNodes[0];
					
					if(!po.isSchemaNode(selNode))
						return;
					
					var schemaId = selNode.original.id;
					
					po.open(contextPath+$.toPath("schema", ($item.hasClass("schema-operation-edit") ? "edit" : "view"))+"?id="+encodeURIComponent(schemaId), 
					{
						"pageParam" :
						{
							"afterSave" : function()
							{
								jstree.refresh(true);
							}
						}
					});
				}
				else if($item.hasClass("schema-operation-delete"))
				{
					if(!selNodes.length)
						return;
					
					po.confirm("<@spring.message code='main.confirmDeleteSchema' />",
					{
						"confirm" : function()
						{
							var schemaIdParam = "";
							
							for(var i=0; i<selNodes.length; i++)
							{
								if(po.isSchemaNode(selNodes[i]))
								{
									if(schemaIdParam != "")
										schemaIdParam += "&";
									
									schemaIdParam += "id=" + selNodes[i].original.id;
								}
							}
							
							$.post(contextPath+"/schema/delete", schemaIdParam, function()
							{
								jstree.refresh(true);
							});
						}
					});
				}
				else if($item.hasClass("schema-operation-refresh"))
				{
					if(!selNodes.length || selNodes.length < 1)
						return;
					
					if(po.isTableNode(selNodes[0]))
					{
						if(selNodes.length != 1)
						{
							$.tipInfo("<@spring.message code='pleaseSelectOnlyOneRow' />");
						}
						else
						{
							var selNode = selNodes[0];
							var schema = jstree.get_node(selNode.parent).original;
							
							var schemaId = schema.id;
				        	var schemaTitle = schema.title;
				        	var tableName = selNode.original.name;
				        	
				        	var tooltipId;
				        	$.model.load(schemaId, tableName,
				    	    {
				        		beforeSend : function beforeSend(XHR)
				        		{
				        			tooltipId = $.tipInfo("<@spring.message code='loading' />", -1);
				        		},
				        		success :  function(model)
				        		{
					        		var tabId = po.genTabId(schemaId, tableName);
					        		
					        		var mainTabs = po.element("#mainTabs");
					        		var uiTabsNav = mainTabs.find(".ui-tabs-nav");
					        		
					        	    var prelia = $("> li > a[href='#"+tabId+"']", uiTabsNav);
					        	    if(prelia.length > 0)
					        	    {
					        	    	$.get(contextPath + $.toPath("data", schemaId, tableName, "query"), function(data)
					        	    	{
					        	    	    uiTabsNav.show();
					        	    	    
					        	    	    $("#"+tabId, mainTabs).html(data);
					        	    	    
						        	    	var myidx = prelia.parent().index();
						        	    	mainTabs.tabs("option", "active",  myidx);
					        	    	 });
					        	    }
				        		},
					        	complete : function()
					        	{
					        		$.closeTip(tooltipId);
					        	}
				        	});
						}
					}
					else if(po.isSchemaNode(selNodes[0]))
					{
						for(var i=0; i<selNodes.length; i++)
						{
							if(po.isSchemaNode(selNodes[i]))
								jstree.refresh_node(selNodes[i]);
						}
					}
				}
				else if($item.hasClass("schema-operation-reload"))
				{
					jstree.refresh(true);
				}
				else if($item.hasClass("schema-operation-sqlpad"))
				{
					if(!selNodes.length || selNodes.length < 1)
						return;
					
					if(selNodes.length != 1)
					{
						$.tipInfo("<@spring.message code='pleaseSelectOnlyOneRow' />");
					}
					else
					{
						var selNode = selNodes[0];
						
						var schema = null;
						
						if(po.isSchemaNode(selNode))
							schema = selNode.original;
						else if(po.isTableNode(selNode))
							schema = jstree.get_node(selNode.parent).original;
						
						if(schema)
						{
							var tabTitle = "<@spring.message code='main.sqlpad' /><@spring.message code='bracketLeft' />" + schema.title + "<@spring.message code='bracketRight' />";
			    			
							var tabUrl = "${contextPath}/sqlpad/" + schema.id;
							
							po.activeWorkTab(po.genTabId(schema.id, "sqlpad"), "<@spring.message code='main.sqlpad' />", tabTitle, schema, tabUrl, "sqlpad");
						}
					}
				}
			}
		});
		
		po.element("#addSchemaButton").click(function()
		{
			var jstree = po.element(".schema-panel-content").jstree(true);
			var selNodes = jstree.get_selected(true);
			
			var copyId = undefined;
			
			if(selNodes.length > 0)
			{
				var selNode = selNodes[0];
				
				if(po.isSchemaNode(selNode))
					copyId = selNode.original.id;
			}
			
			po.open(contextPath+"/schema/add" + (copyId != undefined ? "?copyId="+copyId : ""),
			{
				"pageParam" :
				{
					"afterSave" : function()
					{
						po.refreshSchemaTree();
					}
				}
			});
		});
		
		po.element(".schema-panel-content").jstree
		(
			{
				"core" :
				{
					"data" :
					{
						"type" : "POST",
						"url" : function(node)
						{
							//根节点
							if(node.id == "#")
								return contextPath+"/schema/list";
							else if(po.isSchemaNode(node))
							{
								return contextPath + $.toPath("schema", node.id, "pagingQueryTable");
							}
						},
						"data" : function(node)
						{
							if(node.id == "#")
								return po.getSearchSchemaFormDataForSchema();
							else if(po.isSchemaNode(node))
								return po.getSearchSchemaFormDataForTable();
						},
						"success" : function(data, textStatus, jqXHR)
						{
							var url = this.url;
							
							if(url.indexOf("/schema/list") > -1)
								po.schemaToJstreeNodes(data);
							else if(url.indexOf("/pagingQueryTable") > -1)
							{
								po.toJstreeNodePagingData(data);
							}
						}
					},
					"themes" : {"dots": false, icons: true},
					"check_callback" : true
				}
			}
		)
		.bind("select_node.jstree", function(e, data)
		{
			var tree = $(this).jstree(true);
			
			if(po.isTableNode(data.node))
			{
				var schema = tree.get_node(data.node.parent).original;
				var tableInfo = data.node.original;
				
	        	var tabTitle = (po.isTableView(tableInfo) ? "<@spring.message code='main.tableType.view' />" : "<@spring.message code='main.tableType.table' />") + "<@spring.message code='colon' />" + tableInfo.name;
				if(tableInfo.comment)
					tabTitle += "<@spring.message code='bracketLeft' />" + tableInfo.comment + "<@spring.message code='bracketRight' />";
				tabTitle += "<@spring.message code='bracketLeft' />" + schema.title + "<@spring.message code='bracketRight' />";
    			
				var tabUrl = contextPath + $.toPath("data", schema.id, tableInfo.name, "query");
				
				po.activeWorkTab(po.genTabId(schema.id, tableInfo.name), data.node.text, tabTitle, schema, tabUrl, "table");
			}
			else if(po.isNextPageNode(data.node))
			{
				if(!data.node.state.loadingNextPage)
				{
					data.node.state.loadingNextPage = true;
					
					var schemaNode = tree.get_node(data.node.parent);
					
					var schemaId = schemaNode.id;
					
					var $moreTableNode = tree.get_node(data.node, true);
					$(".more-table", $moreTableNode).html("<@spring.message code='main.loadingTable' />");
					
					var param = po.getSearchSchemaFormDataForTable();
					param = $.extend({}, data.node.original.nextPageInfo, param);
					
					$.ajax(contextPath+$.toPath("schema", schemaId, "pagingQueryTable"),
					{
						data : param,
						success : function(pagingData)
						{
							tree.delete_node(data.node);
							po.toJstreeNodePagingData(pagingData);
							
							var nodes = pagingData.items;
							
							for(var i=0; i<nodes.length; i++)
							{
								tree.create_node(schemaNode, nodes[i]);
							}
						},
						error : function(XMLHttpResponse, textStatus, errorThrown)
						{
							data.node.state.loadingNextPage = false;
							$(".more-table", $moreTableNode).html("<@spring.message code='main.moreTable' />");
						}
					});
				}
			}
		})
		.bind("load_node.jstree", function(e, data)
		{
			var tree = $(this).jstree(true);
			
			if(po.selectNodeAfterLoad)
			{
				po.selectNodeAfterLoad = false;
				
				tree.select_node(data.node);
			}
		});
		
		po.element("#schemaSearchForm").submit(function()
		{
			var jstree = po.element(".schema-panel-content").jstree(true);
			
			if(po.isSearchTable())
			{
				po.selectNodeAfterLoad = true;
				
				var searchSchemaNodes = [];
				
				var selNodes = jstree.get_selected(true);
				for(var i=0; i<selNodes.length; i++)
				{
					var selNode = selNodes[i];
					
					while(selNode && !po.isSchemaNode(selNode))
						selNode = jstree.get_node(selNode.parent);
					
					if(selNode)
						searchSchemaNodes.push(selNode);
				}
				
				//没有选中的话则取第一个
				if(searchSchemaNodes.length == 0)
				{
					var rootNode = jstree.get_node($.jstree.root);
					var firstSchemaNode = (rootNode.children && rootNode.children.length > 0 ? jstree.get_node(rootNode.children[0]) : undefined);
					
					if(firstSchemaNode)
						searchSchemaNodes.push(firstSchemaNode);
				}
				
				for(var i=0; i<searchSchemaNodes.length; i++)
				{
					var searchSchemaNode = searchSchemaNodes[i];
					
					//如果这次的搜索结果为空，下载再搜索的话，节点不会自动打开，
					//使用load_node.jstree事件处理来解决此问题，则会让节点闪烁，效果不好
					//因此这里设置state.opened=true，不会有上述问题
					if(!searchSchemaNode.state.opened)
						searchSchemaNode.state.opened = true;
					
					jstree.refresh_node(searchSchemaNode);
				}
			}
			else
			{
				po.refreshSchemaTree();
			}
		});
		
		po.element("#mainTabs").tabs(
		{
			event: "click",
			activate: function(event, ui)
			{
				var newTab = $(ui.newTab);
				var newPanel = $(ui.newPanel);
				
				po.refreshTabsNav($(this), newTab);
				
				var newSchemaId = newTab.attr("schema-id");
				
				$(".ui-tabs-nav .category-bar", this).removeClass("ui-state-active");
				$(".ui-tabs-nav .category-bar.category-bar-"+newSchemaId, this).addClass("ui-state-active");
				
				var panelShowCallback = newPanel.data("showCallback");
				if(panelShowCallback)
					panelShowCallback();
			}
		});
		
		po.element("#mainTabs .ui-tabs-nav").hide();
		
		po.getTabsHiddens = function(tabsNav)
		{
			var tabsNavHeight = tabsNav.height();
			
			var hiddens = [];
			
			$("li.ui-tabs-tab", tabsNav).each(function()
			{
				var li = $(this);
				
				if(li.is(":hidden") || li.position().top >= tabsNavHeight)
					hiddens.push(li);
			});
			
			return hiddens;
		};
		
		po.refreshTabsNav = function(tabs, activeTab)
		{
			var tabsNav = po.element(".ui-tabs-nav", tabs);
			
			if(activeTab == undefined)
				activeTab = $("li.ui-tabs-active", tabsNav);
			
			$("li.ui-tabs-tab", tabsNav).show();
			
			if(activeTab && activeTab.length > 0)
			{
				//如果卡片不可见，则向前隐藏卡片，直到此卡片可见
				
				var tabsNavHeight = tabsNav.height();
				
				var activeTabPosition;
				var prevHidden = activeTab.prev();
				while((activeTabPosition = activeTab.position()).top >= tabsNavHeight)
				{
					prevHidden.hide();
					prevHidden = prevHidden.prev();
				}
			}
			
			var showHiddenButton = $(".tab-show-hidden", tabs);
			
			if(po.getTabsHiddens(tabsNav).length > 0)
			{
				if(showHiddenButton.length == 0)
				{
					showHiddenButton = $("<button class='ui-button ui-corner-all ui-widget ui-button-icon-only tab-show-hidden'><span class='ui-icon ui-icon-triangle-1-s'></span></button>").appendTo(tabs);
					showHiddenButton.click(function()
					{
						var tabs = po.element("#mainTabs");
						var tabsNav = po.element(".ui-tabs-nav", tabs);
						
						var hiddens = po.getTabsHiddens(tabsNav);
						
						var menu = po.element("#tabMoreTabMenu");
						menu.empty();
						
						for(var i=0; i<hiddens.length; i++)
						{
							var tab = hiddens[i];
							
							var mi = $("<li />").appendTo(menu);
							mi.attr("tab-id", tab.attr("id"));
							$("<div />").html($(".ui-tabs-anchor", tab).text()).attr("title", tab.attr("title")).appendTo(mi);
						}
						
		    	    	po.element("#tabMoreTabMenuParent").show().css("left", "0px").css("top", "0px")
		    	    		.position({"my" : "left top+1", "at": "right bottom", "of" : $(this), "collision": "flip flip"});
		    	    	
						menu.menu("refresh");
					});
				}
				
				showHiddenButton.show();
			}
			else
				showHiddenButton.hide();
		};
		
		po.element("#tabMoreOperationMenu").menu(
		{
			select: function(event, ui)
			{
				var item = ui.item;
				var schemaId = $(this).attr("schema-id");
				var tabUrl = $(this).attr("tab-url");
				var tabId = $(this).attr("tab-id");
				
				var mainTabs = po.element("#mainTabs");
				var uiTabsNav = mainTabs.find(".ui-tabs-nav");
				var tabLink = $("a[href='"+tabId+"']", uiTabsNav);
				var tabLi = tabLink.parent();
				
				if(item.hasClass("tab-operation-newwin"))
				{
					window.open(tabUrl);
				}
				else if(item.hasClass("tab-operation-close-left"))
				{
					var prev;
					while((prev = tabLi.prev()).length > 0)
					{
						var preTabId = $("a", prev).attr("href");
						
						$(preTabId, mainTabs).remove();
						prev.remove();
					}
					
					mainTabs.tabs("refresh");
					po.refreshTabsNav(mainTabs);
				}
				else if(item.hasClass("tab-operation-close-right"))
				{
					var next;
					while((next = tabLi.next()).length > 0)
					{
						var nextTabId = $("a", next).attr("href");
						
						$(nextTabId, mainTabs).remove();
						next.remove();
					}
					
					mainTabs.tabs("refresh");
					po.refreshTabsNav(mainTabs);
				}
				else if(item.hasClass("tab-operation-close-other"))
				{
					$("li", uiTabsNav).each(function()
					{
						if(tabLi[0] == this)
							return;
						
						var li = $(this);
						
						var tabId = $("a", li).attr("href");

						$(tabId, mainTabs).remove();
						li.remove();
					});
					
					mainTabs.tabs("refresh");
					po.refreshTabsNav(mainTabs);
				}
				else if(item.hasClass("tab-operation-close-all"))
				{
					$("li", uiTabsNav).each(function()
					{
						var li = $(this);
						
						var tabId = $("a", li).attr("href");

						$(tabId, mainTabs).remove();
						li.remove();
					});
					
					mainTabs.tabs("refresh");
					po.refreshTabsNav(mainTabs);
				}
				
				if($("li", uiTabsNav).length == 0)
					uiTabsNav.hide();
				
				po.element("#tabMoreOperationMenuParent").hide();
			}
		});
		
		po.element("#tabMoreTabMenu").menu(
		{
			select: function(event, ui)
			{
				var item = ui.item;
				var tabId = item.attr("tab-id");
				
				var mainTabs = po.element("#mainTabs");
				var myIndex = po.element(".ui-tabs-nav li[id='"+tabId+"']", mainTabs).index();
		    	mainTabs.tabs("option", "active",  myIndex);
				
				po.element("#tabMoreTabMenuParent").hide();
			}
		});
		
		$(document.body).click(function(e)
		{
			var target = $(e.target);
			
			var hide = true;
			
			while(target && target.length != 0)
			{
				if(target.hasClass("tab-operation-more") || target.hasClass("tab-more-operation-menu-parent"))
				{
					hide = false;
					break;
				}
				
				target = target.parent();
			};
			
			if(hide)
				po.element("#tabMoreOperationMenuParent").hide();
		});

		$(document.body).click(function(e)
		{
			var target = $(e.target);
			
			var hide = true;
			
			while(target && target.length != 0)
			{
				if(target.hasClass("tab-show-hidden") || target.hasClass("tab-more-tab-menu-parent"))
				{
					hide = false;
					break;
				}
				
				target = target.parent();
			};
			
			if(hide)
				po.element("#tabMoreTabMenuParent").hide();
		});
		
		//系统通知
		$.get("${contextPath}/notification/list", function(data)
		{
			if(data && data.length)
			{
				for(var i=0; i< data.length; i++)
				{
					$.tipInfo(data[i].content);
				}
			}
		});
	});
})
(${pageId});
</script>
</head>
<body id="${pageId}">
<div class="main-page-head">
	<#include "include/html_logo.ftl">
	<div class="toolbar">
		<ul id="systemSetMenu" class="lightweight-menu">
			<li class="system-set-root"><span><span class="ui-icon ui-icon-gear"></span></span>
				<ul style="display:none;" class="ui-widget-shadow">
					<#if !currentUser.anonymous>
					<#if currentUser.admin>
					<li class="system-set-driverEntity-manage"><a href="javascript:void(0);"><@spring.message code='main.manageDriverEntity' /></a></li>
					<li class="system-set-driverEntity-add"><a href="javascript:void(0);"><@spring.message code='main.addDriverEntity' /></a></li>
					<li class="ui-widget-header"></li>
					<li class="system-set-user-manage"><a href="javascript:void(0);"><@spring.message code='main.manageUser' /></a></li>
					<li class="system-set-user-add"><a href="javascript:void(0);"><@spring.message code='main.addUser' /></a></li>
					<li class="ui-widget-header"></li>
					</#if>
					<li class="system-set-personal-set"><a href="javascript:void(0);"><@spring.message code='main.personalSet' /></a></li>
					<#if currentUser.admin>
					<li class=""><a href="javascript:void(0);"><@spring.message code='main.globalSetting' /></a>
						<ul class="ui-widget-shadow">
							<li class="system-set-global-setting"><a href="javascript:void(0);"><@spring.message code='globalSetting.smtpSetting' /></a></li>
							<li class="system-set-schema-url-builder"><a href="javascript:void(0);"><@spring.message code='schemaUrlBuilder.schemaUrlBuilder' /></a></li>
						</ul>
					</li>
					</#if>
					<li class="ui-widget-header"></li>
					</#if>
					<li class=""><a href="javascript:void(0);"><@spring.message code='main.changeTheme' /></a>
						<ul class="ui-widget-shadow">
							<li class="theme-item" theme="lightness"><a href="javascript:void(0);"><@spring.message code='main.changeTheme.lightness' /><span class="ui-widget ui-widget-content theme-sample theme-sample-lightness"></span></a></li>
							<li class="theme-item" theme="dark"><a href="javascript:void(0);"><@spring.message code='main.changeTheme.dark' /><span class="ui-widget ui-widget-content theme-sample theme-sample-dark"></span></a></li>
							<li class="theme-item" theme="green"><a href="javascript:void(0);"><@spring.message code='main.changeTheme.green' /><span class="ui-widget ui-widget-content theme-sample theme-sample-green"></span></a></li>
						</ul>
					</li>
					<li><a href="javascript:void(0);"><@spring.message code='help' /></a>
						<ul class="ui-widget-shadow">
							<li class="about"><a href="javascript:void(0);"><@spring.message code='main.about' /></a></li>
							<li class="documentation"><a href="javascript:void(0);"><@spring.message code='main.documentation' /></a></li>
							<li class="changelog"><a href="javascript:void(0);"><@spring.message code='main.changelog' /></a></li>
						</ul>
					</li>
				</ul>
			</li>
		</ul>
		<#if !currentUser.anonymous>
		<div class="user-name">
		${currentUser.nameLabel?html}
		</div>
		<a class="link" href="${contextPath}/logout"><@spring.message code='main.logout' /></a>
		<#else>
		<a class="link" href="${contextPath}/login"><@spring.message code='main.login' /></a>
		<#if !disableRegister>
		<a class="link" href="${contextPath}/register"><@spring.message code='main.register' /></a>
		</#if>
		</#if>
	</div>
</div>
<div class="main-page-content">
	<div class="ui-layout-west">
		<div class="ui-widget ui-widget-content schema-panel">
			<div class="schema-panel-head">
				<div class="schema-panel-title"><@spring.message code='main.schema' /></div>
				<div class="schema-panel-operation">
					<div class="ui-widget ui-widget-content ui-corner-all search">
						<form id="schemaSearchForm" action="javascript:void(0);">
							<div id="schemaSearchSwitch" class="schema-search-switch"><span class="ui-icon ui-icon-document search-switch-icon" title="<@spring.message code='main.searchTable' />"></span></div>
							<div class="keyword-input-parent"><input name="keyword" type="text" value="" class="ui-widget ui-widget-content keyword-input" /></div>
							<button type="submit" class="ui-button ui-corner-all ui-widget ui-button-icon-only search-button"><span class="ui-icon ui-icon-search"></span><span class="ui-button-icon-space"> </span><@spring.message code='find' /></button>
							<input name="pageSize" type="hidden" value="100" />
						</form>
					</div>
					<button id="addSchemaButton" class="ui-button ui-corner-all ui-widget ui-button-icon-only add-schema-button" title="<@spring.message code='main.addSchema' />"><span class="ui-button-icon ui-icon ui-icon-plus"></span><span class="ui-button-icon-space"> </span><@spring.message code='add' /></button>
					<ul id="schemaOperationMenu" class="lightweight-menu">
						<li class="schema-operation-root"><span><span class="ui-icon ui-icon-triangle-1-s"></span></span>
							<ul class="ui-widget-shadow">
								<li class="schema-operation-edit"><a href="javascript:void(0);"><@spring.message code='edit' /></a></li>
								<li class="schema-operation-delete"><a href="javascript:void(0);"><@spring.message code='delete' /></a></li>
								<li class="schema-operation-view"><a href="javascript:void(0);"><@spring.message code='view' /></a></li>
								<li class="schema-operation-refresh" title="<@spring.message code='main.schemaOperationMenuRefreshComment' />"><a href="javascript:void(0);"><@spring.message code='refresh' /></a></li>
								<li class="ui-widget-header"></li>
								<li class="schema-operation-reload" title="<@spring.message code='main.schemaOperationMenuReloadComment' />"><a href="javascript:void(0);"><@spring.message code='reload' /></a></li>
								<li class="ui-widget-header"></li>
								<li class="schema-operation-sqlpad"><a href="javascript:void(0);"><@spring.message code='main.sqlpad' /></a></li>
							</ul>
						</li>
					</ul>
				</div>
			</div>
			<div class="schema-panel-content">
			</div>
		</div>
	</div>
	<div class="ui-layout-center">
		<div id="mainTabs" class="main-tabs">
			<ul>
			</ul>
		</div>
		<div id="tabMoreOperationMenuParent" class="ui-widget ui-front ui-widget-content ui-corner-all ui-widget-shadow tab-more-operation-menu-parent" style="position: absolute; left:0px; top:0px; display: none;">
			<ul id="tabMoreOperationMenu" class="tab-more-operation-menu">
				<li class="tab-operation-close-left"><div><@spring.message code='main.closeLeft' /></div></li>
				<li class="tab-operation-close-right"><div><@spring.message code='main.closeRight' /></div></li>
				<li class="tab-operation-close-other"><div><@spring.message code='main.closeOther' /></div></li>
				<li class="tab-operation-close-all"><div><@spring.message code='main.closeAll' /></div></li>
				<li class="ui-widget-header"></li>
				<li class="tab-operation-newwin"><div><@spring.message code='main.openInNewWindow' /></div></li>
			</ul>
		</div>
		<div id="tabMoreTabMenuParent" class="ui-widget ui-front ui-widget-content ui-corner-all ui-widget-shadow tab-more-tab-menu-parent" style="position: absolute; left:0px; top:0px; display: none;">
			<ul id="tabMoreTabMenu" class="tab-more-tab-menu">
			</ul>
		</div>
	</div>
</div>
</body>
</html>