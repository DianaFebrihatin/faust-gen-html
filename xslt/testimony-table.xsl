<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:f="http://www.faustedition.net/ns"
	xmlns="http://www.w3.org/1999/xhtml"
	xpath-default-namespace="http://www.faustedition.net/ns"
	exclude-result-prefixes="xs"
	version="2.0">
		
	<xsl:import href="utils.xsl"/>
	<xsl:import href="testimony-common.xsl"/>
	<xsl:include href="html-frame.xsl"/>
	
	<xsl:strip-space elements="*"/>	
	
	
	<xsl:param name="output" select="resolve-uri('testimony-split/', $builddir-resolved)"/>
	
	<!-- XML version of the testimony table, generated by get-testimonies.py from the excel table -->
	<xsl:param name="table" select="doc('testimony-table.xml')"/>	
	
	<!-- input is the Mapping id -> file, generated by workflow from testimony xmls -->
	<xsl:param name="usage" select="/"/>
	
	<!-- Machine-readable bibliography, generated by python script from wiki page : -->
	<xsl:variable name="bibliography" select="doc('bibliography.xml')"/>

	<!-- 
		
		The following variable defines the available columns. To define a new column, you
		should copy the corresponding <fieldspec> element from testimony-table.xml to the
		right place in the variable below and adjust it accordingly.
		
		Attributes:
		
			- label: label as used in the <field> attributes
			- spreadsheet: original label from spreadsheet, for reference only
			- sortable-type: sort order for sortable
			
		Content:
		
			The element content is copied 1:1 to the corresponding <th> element
	
	-->
	<xsl:variable name="columns" xmlns="http://www.faustedition.net/ns">
		<fieldspec name="graef-nr" spreadsheet="Gräf-Nr." sortable-type="numericplus" title="Nr. in Gräf II 2">Gräf</fieldspec>
		<fieldspec name="pniower-nr" spreadsheet="Pniower-Nr." sortable-type="numericplus" title="Nr. in Pniower 1899">Pniower</fieldspec>
		<fieldspec name="quz" spreadsheet="QuZ" title="Nr. in Quellen und Zeugnisse">QuZ</fieldspec>
		<fieldspec name="biedermann-herwignr" spreadsheet=" Biedermann-HerwigNr." title="Nr. bei Biedermann / Herwig">Biedermann³</fieldspec>
		<fieldspec name="datum-von" spreadsheet="Datum.(von)" sortable-type="date-de">Datum</fieldspec>
		<fieldspec name="dokumenttyp" spreadsheet="Dokumenttyp">Beschreibung</fieldspec>		
		<fieldspec name="excerpt" generated="true">Auszug</fieldspec>
	</xsl:variable>
	
	<xsl:function name="f:field-label">
		<xsl:param name="name"/>
		<xsl:value-of select="$columns/fieldspec[@name = $name]/node()"/>
	</xsl:function>
	
	
	
	<!-- Used for the message column. Can be removed once there are no more warnings etc. -->
	<xsl:param name="extrastyle">
		<style type="text/css">
			.message { border: 1px solid transparent; border-radius: 1px; padding: 1px; margin: 1px;}
			.message.error { color: rgb(190,0,0); border-color: rgb(190,0,0); background-color: rgba(190,0,0,0.1); }
			.message.warning { color: black; background-color: rgba(220,160,0,0.2); border-color: rgb(220,160,0); }
			.message.info  { color: rgb(0,0,190); border-color: rgb(0,0,190); background-color: rgba(0,0,190,0.1); }
		</style>
	</xsl:param>
	
	<xsl:template match="/testimony-index">
		<xsl:for-each select="$table">
			<xsl:call-template name="start"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="start">
		<xsl:call-template name="html-frame">
			<xsl:with-param name="headerAdditions"><xsl:copy-of select="$extrastyle"/></xsl:with-param>
			<xsl:with-param name="scriptAdditions">
				requirejs(['sortable', 'jquery', 'jquery.table'], function(Sortable, $, $table) {
					$(function() {
						document.getElementById("breadcrumbs").appendChild(Faust.createBreadcrumbs([{caption: "Archiv", link: "archive"}, {caption: "Dokumente zur Entstehungsgeschichte"}]));
						Sortable.initTable(document.getElementById('testimony-table'));
                        $("table[data-sortable]").fixedtableheader();
					});						
				});
			</xsl:with-param>
			<xsl:with-param name="content">
				
				<div id="testimony-table-container">
					<table data-sortable='true' class='pure-table' id="testimony-table">
						<thead>
							<tr>
								<xsl:for-each select="$columns/fieldspec">
									<th data-sorted="false"
										data-sortable-type="{if (@sortable-type) then @sortable-type else 'alpha'}"
										title="{@title}"
										id="th-{@name}"> 
										<xsl:copy-of select="node()"/>
									</th>
								</xsl:for-each>	
							</tr>
						</thead>
						<tbody>
							<xsl:apply-templates/>
						</tbody>
					</table>
				</div>
				
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	
	
	<!-- 
	
		Rendering a single testimony to a row works as follows:
		
		1. first, all additional data like usage and bibliography information are collected. There are also some consistency checks
		   that result in <message> elements.
		   
		2. then, we're adding additional empty <field name="…"/> elements for all fields in $columns but not in the current 
		   entry.

        3. finally, for each fieldspec in $column, we call <xsl:apply-templates/> on the corresponding <field/> from step 1/2.
           This should generate the actual <td> for the column. There are default implementations below.
	
	-->
	<xsl:template match="citation|testimony">
		<xsl:variable name="entry" select="."/>
		<xsl:variable name="lbl" select="string-join(
			for $field in field return if ($field/text()) then concat(string-join($columns/fieldspec[@label=$field/@label], ''), ': ', $field) else (),
			', ')"/>
		<xsl:variable name="used" select="$usage//*[@testimony=current()/@id]"/>
		
		<!-- We're building an XML fragment that will finally be moved into the current <testimony> entry -->
		<xsl:variable name="rowinfo_raw">
			
			<!-- now a bunch of assertions -->
			<xsl:choose>
				<xsl:when test="not($used) and $entry//field[@name='h-sigle']">
					<xsl:variable name="pseudoid" select="f:get-or-create-id($entry)"/>
					<f:href><xsl:value-of select="concat('testimony/', $pseudoid)"/></f:href>
					<f:field name="excerpt">[Beschreibung]</f:field>
					<f:generate-tei>sigil</f:generate-tei>					
				</xsl:when>
				<xsl:when test="not($used) and (not(@id) or @id = '')">
					<xsl:variable name="pseudoid" select="f:get-or-create-id($entry)"/>
					<f:href><xsl:value-of select="concat('testimony/', $pseudoid)"/></f:href>
					<f:field name="excerpt">[Beschreibung]</f:field>
					<f:generate-tei>no-id</f:generate-tei>
				</xsl:when>
				<xsl:when test="contains(@id, ' ')">
					<f:message status="error">Ganz komische ID: »<xsl:value-of select="@id"/>«</f:message>
				</xsl:when>
				<xsl:when test="not($used)">
					<!--<f:message status="info">kein XML für »<xsl:value-of select="@id"/>«</f:message>-->
					<f:href><xsl:value-of select="concat('testimony/', @id)"/></f:href>
					<f:field name="excerpt">[Beschreibung]</f:field>
					<f:generate-tei>no-xml</f:generate-tei>
				</xsl:when>
				<xsl:otherwise>
					<f:base><xsl:value-of select="$used/@base"/></f:base>
					<f:href><xsl:value-of select="concat('testimony/', @id)(: $used/@base, '#', $used/@testimony-id):)"/></f:href>
					<xsl:variable name="bibref" select="normalize-space($used[1]/text())"/>
					<xsl:variable name="bib" select="$bibliography//bib[@uri=$bibref]"/> <!-- TODO refactor to bibliography.xsl -->
					<xsl:copy-of select="$bib"/>
					<xsl:variable name="excerpt" select="$used/@rs"/>
					
					<xsl:if test="not($excerpt)">
						<f:message status="info">kein Auszug</f:message>
					</xsl:if>
					<f:field name="excerpt"><xsl:value-of select="$excerpt"/></f:field>
					<xsl:if test="not($bib)">
						<f:message status="warning">kein Literaturverzeichniseintrag für <xsl:value-of select="$bibref"/></f:message>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="rowinfo" as="element()">
			<xsl:copy>
				<xsl:attribute name="id" select="f:get-or-create-id($entry)"/>
				<xsl:copy-of select="@*"/>
				<xsl:sequence select="*"/>
				<xsl:sequence select="$rowinfo_raw"/>
				<xsl:for-each select="$columns/fieldspec">
					<xsl:if test="not(@name = ($entry//field/@name, $rowinfo_raw/field/@name))">
						<f:field name="{@name}"/>
					</xsl:if>
				</xsl:for-each>
			</xsl:copy>
		</xsl:variable>
				
		<tr id="{$rowinfo/@id}">
			<xsl:for-each select="$columns//fieldspec">
				<xsl:variable name="fieldname" select="@name"/>
				<xsl:apply-templates select="$rowinfo//field[@name=$fieldname]"/>
			</xsl:for-each>
		</tr>
	</xsl:template>
		
	<xsl:template match="field">
		<td title="{if (normalize-space(.)) then concat(f:field-label(@name), ': ', .) else f:field-label(@name)}">
			<xsl:apply-templates/>
		</td>
	</xsl:template>
	
	<xsl:template match="field[@name='dokumenttyp']">
		<td title="Beschreibung">
			<xsl:call-template name="render-dokumenttyp"/>			
		</td>
	</xsl:template>
	
	<xsl:template match="field[@name='excerpt']">
		<td>			
			<xsl:if test="../field[@name='h-sigle']">				
				<xsl:variable name="sigils" select="normalize-space(../field[@name='h-sigle']/text())"/>
				<xsl:text>→ </xsl:text>
				<xsl:sequence select="f:sigil-links($sigils)"/>
				<xsl:text> / </xsl:text>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="normalize-space(.)">
					<a href="{../href}"><xsl:apply-templates/></a>				
				</xsl:when>
				<xsl:otherwise>
					<a href="{../href}">Beschreibung</a>
				</xsl:otherwise>
			</xsl:choose>
			
			<xsl:for-each select="../message">
				<xsl:comment><xsl:value-of select="."/></xsl:comment>
			</xsl:for-each>
		</td>
	</xsl:template>
	
	<xsl:template match="messages">
		<xsl:for-each select="message">
			<xsl:message select="concat(upper-case(@status), ':', ../../base, ':', ., ' (', ../../@lbl, ')')"/>			
		</xsl:for-each>
	</xsl:template>
	
	<xsl:function name="f:get-or-create-id" as="xs:string">
		<xsl:param name="entry"/><!-- f:testimony -->
		<xsl:for-each select="$entry"><!-- focus -->
			<xsl:choose>
				<xsl:when test="@id"><xsl:value-of select="@id"/></xsl:when>
				<xsl:when test="f:find-inferior-id(.)">
					<xsl:value-of select="f:find-inferior-id(.)"/>
				</xsl:when>				
				<xsl:otherwise>
					<xsl:variable name="src" select="f:field[starts-with(@name, 'lfd-nr')][1]"/>
					<xsl:value-of select="concat($src/@name, '_', $src)"/>
				</xsl:otherwise>
			</xsl:choose>			
		</xsl:for-each>
	</xsl:function>
	
	<xsl:function name="f:find-inferior-id" as="xs:string?">
		<xsl:param name="entry"/><!-- f:testimony w/o @id -->
		<xsl:variable name="candidate-ids" select="for $f in $entry//f:field return concat($f/@name, '_', $f)"/>
		<xsl:sequence select="($candidate-ids[. = $usage//f:citation/@testimony])[1]"/>
	</xsl:function>

	<xsl:template name="generate-pseudo-testimonies">
		<xsl:message>Generating empty testimony files ...</xsl:message>
		<xsl:for-each-group select="$table//f:testimony" group-by="f:get-or-create-id(.)">
			<xsl:variable name="id" select="current-grouping-key()"/>
			<xsl:for-each select="current-group()[1]">
				<xsl:choose>
					<xsl:when test="$id = $usage//*/@testimony">
						<!--<xsl:message>Skipping testimony generation (<xsl:value-of select="$id"/>)</xsl:message>-->
					</xsl:when>
					<xsl:otherwise>
						<!--<xsl:message>Running testimony generation (<xsl:value-of select="$id"/>)</xsl:message>-->
						<xsl:call-template name="create-empty-tei"/>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:for-each>
		</xsl:for-each-group>
	</xsl:template>
	
	<xsl:template name="create-empty-tei">			
			<xsl:choose>
				<xsl:when test="not(self::f:testimony)">
					<xsl:message>Cannot create empty testimony TEI for non-testimony element <xsl:value-of select="name()"/></xsl:message>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="id" select="f:get-or-create-id(.)"/>
					<xsl:variable name="filename" select="resolve-uri(concat($id, '.xml'), $output)"/>
					<!--<xsl:message>Creating empty testimony TEI <xsl:value-of select="$filename"/></xsl:message>-->
					<xsl:result-document href="{$filename}" exclude-result-prefixes="xs f">
						<TEI xmlns="http://www.tei-c.org/ns/1.0">
							<teiHeader>
								<xsl:comment>Preliminary TEI header</xsl:comment>
								<xenoData>
									<xsl:copy>
										<xsl:attribute name="id" select="$id"/>
										<xsl:copy-of select="@* except @id"/>
										<xsl:copy-of select="node()"/>
									</xsl:copy>
								</xenoData>
							</teiHeader>
							<text>
								<group>
									<text>
										<body>
											<desc type="editorial" subtype="info">
												<xsl:choose>
													<xsl:when test=".//field[@name='h-sigle']">
														<xsl:variable name="sigils" select="f:field[@name='h-sigle']/text()"/>
														Entspricht <xsl:sequence select="f:sigil-links($sigils)"/>
													</xsl:when>
													<xsl:otherwise>
														noch kein Text vorhanden
													</xsl:otherwise>
												</xsl:choose>
											</desc>
										</body>										
									</text>
								</group>
							</text>
						</TEI>
					</xsl:result-document>
				</xsl:otherwise>
			</xsl:choose>
	</xsl:template>
	
	
</xsl:stylesheet>
