<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis version="2.18.26" minimumScale="0" maximumScale="1e+08" readOnly="0" hasScaleBasedVisibilityFlag="0">
  <edittypes>
    <edittype widgetv2type="TextEdit" name="gid">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="feed_id">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="agency_id_int">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="agency_id">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="agency_name">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="ValueMap" name="route_type">
      <widgetv2config fieldEditable="1" constraint="" labelOnTop="0" constraintDescription="" notNull="0">
        <value key="Car ou bus" value="3"/>
        <value key="Fer" value="2"/>
        <value key="Ferry" value="4"/>
        <value key="Funiculaire" value="7"/>
        <value key="Métro" value="1"/>
        <value key="Tous modes" value="8"/>
        <value key="Tram" value="0"/>
        <value key="Transport par câble (au sol)" value="5"/>
        <value key="Transport par câble (aérien)" value="6"/>
      </widgetv2config>
    </edittype>
    <edittype widgetv2type="TextEdit" name="services_days">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="days">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="veh_km">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="zones_list">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
    <edittype widgetv2type="TextEdit" name="zones_pop">
      <widgetv2config IsMultiline="0" fieldEditable="1" constraint="" UseHtml="0" labelOnTop="0" constraintDescription="" notNull="0"/>
    </edittype>
  </edittypes>
  <annotationform></annotationform>
  <aliases>
    <alias field="gid" index="0" name=""/>
    <alias field="feed_id" index="1" name="Source données"/>
    <alias field="agency_id_int" index="2" name="Id unique opérateur"/>
    <alias field="agency_id" index="3" name="Id initial opérateur"/>
    <alias field="agency_name" index="4" name="Nom opérateur"/>
    <alias field="route_type" index="5" name="Mode"/>
    <alias field="services_days" index="6" name="Jours desservis"/>
    <alias field="days" index="7" name="Jours calcul"/>
    <alias field="veh_km" index="8" name="véh.km (jour)"/>
    <alias field="zones_list" index="9" name="Zones desservies"/>
    <alias field="zones_pop" index="10" name="Pop zones desservies"/>
  </aliases>
  <excludeAttributesWMS/>
  <excludeAttributesWFS/>
  <attributeactions default="-1"/>
  <attributetableconfig actionWidgetStyle="dropDown" sortExpression="&quot;gid&quot;" sortOrder="0">
    <columns>
      <column width="-1" hidden="0" type="field" name="gid"/>
      <column width="-1" hidden="0" type="field" name="feed_id"/>
      <column width="118" hidden="0" type="field" name="agency_id_int"/>
      <column width="129" hidden="0" type="field" name="agency_id"/>
      <column width="96" hidden="0" type="field" name="agency_name"/>
      <column width="98" hidden="0" type="field" name="route_type"/>
      <column width="100" hidden="0" type="field" name="services_days"/>
      <column width="100" hidden="0" type="field" name="days"/>
      <column width="107" hidden="0" type="field" name="veh_km"/>
      <column width="125" hidden="0" type="field" name="zones_list"/>
      <column width="130" hidden="0" type="field" name="zones_pop"/>
      <column width="-1" hidden="1" type="actions"/>
    </columns>
  </attributetableconfig>
  <editform></editform>
  <editforminit/>
  <editforminitcodesource>0</editforminitcodesource>
  <editforminitfilepath></editforminitfilepath>
  <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
Les formulaires QGIS peuvent avoir une fonction Python qui sera appelée à l'ouverture du formulaire.

Utilisez cette fonction pour ajouter plus de fonctionnalités à vos formulaires.

Entrez le nom de la fonction dans le champ "Fonction d'initialisation Python".
Voici un exemple à suivre:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
    geom = feature.geometry()
    control = dialog.findChild(QWidget, "MyLineEdit")

]]></editforminitcode>
  <featformsuppress>0</featformsuppress>
  <editorlayout>generatedlayout</editorlayout>
  <widgets/>
  <conditionalstyles>
    <rowstyles>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#008000" rule="route_type=0" name="Tram" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#ff0000" rule="route_type=1" name="Métro" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#0000ff" rule="route_type=2" name="Fer" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#ffa500" rule="route_type=3" name="Car ou bus" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#00c3fe" rule="route_type=4" name="Ferry" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#ffff00" rule="route_type=5 or route_type=6" name="Transport par câble" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#800080" rule="route_type=7" name="Funiculaire" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
      <style text_color_alpha="0" background_color_alpha="102" background_color="#000000" rule="route_type = 8" name="Tous modes" text_color="#000000">
        <font description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
      </style>
    </rowstyles>
    <fieldstyles/>
  </conditionalstyles>
  <defaults>
    <default field="gid" expression=""/>
    <default field="feed_id" expression=""/>
    <default field="agency_id_int" expression=""/>
    <default field="agency_id" expression=""/>
    <default field="agency_name" expression=""/>
    <default field="route_type" expression=""/>
    <default field="services_days" expression=""/>
    <default field="days" expression=""/>
    <default field="veh_km" expression=""/>
    <default field="zones_list" expression=""/>
    <default field="zones_pop" expression=""/>
  </defaults>
  <previewExpression>COALESCE("gid", '&lt;NULL>')</previewExpression>
  <layerGeometryType>4</layerGeometryType>
</qgis>
