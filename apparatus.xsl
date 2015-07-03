<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:f="http://www.faustedition.net/ns"
	xpath-default-namespace="http://www.tei-c.org/ns/1.0"
	exclude-result-prefixes="xs f"
	version="2.0">
	
	<xsl:import href="html-frame.xsl"/>
	<xsl:include href="html-common.xsl"/>
	<xsl:param name="type">archivalDocument</xsl:param>
	
	<xsl:param name="headerAdditions">
		<script type="text/javascript" src="faust_app_tmp.js"/>
	</xsl:param>
	
	<xsl:output method="xhtml" indent="yes"/>



	<xsl:template match="add[not(parent::subst)]">		
		<xsl:call-template name="enclose">
			<xsl:with-param name="pre" select="'⟨'"/>
			<xsl:with-param name="post"> <span class="app"> erg</span>⟩</xsl:with-param>
			<xsl:with-param name="title" select="concat('»', ., '« ergänzt')"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="del[not(parent::subst)]">
		<span class="appnote" title="{concat('»', ., '« getilgt')}">
			<span class="deleted"><xsl:apply-templates/> </span>
			<span class="generated-text">⟨<span class="app">tilgt</span>⟩</span>			
		</span>
	</xsl:template>
	
	<xsl:template match="del[@f:revType='instant']" priority="1">
		<xsl:call-template name="enclose">
			<xsl:with-param name="with" select="('⟨', ' &gt;⟩')"/>
			<xsl:with-param name="title" select="concat('»', ., '« sofort getilgt')"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="subst">
		<span class="appnote" title="{concat('»', normalize-space(string-join(del, '')), '« durch »', normalize-space(string-join(add, '')), '« ersetzt')}">
			<span class="deleted replaced">
				<xsl:apply-templates select="del"/>
			</span>			
			<xsl:for-each select="add">
				<xsl:call-template name="enclose">
					<xsl:with-param name="with" select="(' ⟨: ', '⟩')"/>
				</xsl:call-template>
			</xsl:for-each>
		</span>
	</xsl:template>

	<!-- 
		Double Replacement
		
		The following construct:
		
		Eine <subst>
				<del><subst>
             	 	   <del>simple</del>
             			<add>einfache</add>
          			</subst>
          		</del>
     			<add>zweifache</add>
  			  </subst> Ersetzung.
  		
  		should be contracted to »Eine simple ⟨: einfache : zweifache ⟩ Ersetzung«. 
  		
  		However, this is only applicable if the inner <subst> is the only non-whitespace child of the outer del. 

	-->
	<xsl:template match="subst[del/subst][f:only-child(del, del/subst)]">
		<span class="appnote" title="{concat('»', normalize-space(string-join(del/subst/del, '')), 
			'« zunächst durch »', normalize-space(string-join(del/subst/add, '')), 
			'«, dann durch »', normalize-space(string-join(add, '')), '« ersetzt')}">
			<span class="deleted replaced">
				<xsl:apply-templates select="del/subst/del"/>
			</span>
			<span class="generated-text">⟨: </span>
			<xsl:apply-templates select="del/subst/add"/>
			<span class="generated-text"> : </span>
			<xsl:apply-templates select="add"/>
			<span class="generated-text">⟩</span>
		</span>
	</xsl:template>

	<xsl:function name="f:normalized-text" as="xs:string">
		<xsl:param name="seq" as="node()*"/>
		<xsl:message select="$seq"/>
		<xsl:value-of select="normalize-space(string-join($seq, ''))"/>
	</xsl:function>

	<xsl:function name="f:same-text-content" as="xs:boolean">
		<xsl:param name="a"/>
		<xsl:param name="b"/>
		<xsl:value-of select="f:normalized-text($a) = f:normalized-text($b)"/>
	</xsl:function>
	
	<xsl:function name="f:only-child" as="xs:boolean">
		<xsl:param name="parent"/>
		<xsl:param name="child"/>
		<xsl:choose>
			<xsl:when test="count($parent/child::*) != 1">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:when test="not($parent/child::* is $child)">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:when test="f:normalized-text(($child/preceding-sibling::text(), $child/following-sibling::text()))">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

	<xsl:template match="del[f:only-child(., restore)]|restore[f:only-child(., del)]" priority="1">
		<span class="appnote">
			<xsl:attribute name="title">
				<xsl:text>»</xsl:text>
				<xsl:value-of select="f:normalized-text(child::*)"/>
				<xsl:text>« zunächst getilgt, dann wiederhergestellt</xsl:text>
			</xsl:attribute>
			<span class="deleted restored">
				<xsl:apply-templates select="child::*/node()"/>
			</span>
			<span class="generated-text">⟨tilgt wdhgst⟩</span>
		</span>
	</xsl:template>


	<xsl:template match="/">
		<xsl:for-each select="/TEI/text">
			<xsl:call-template name="generate-html-frame"/>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:key name="alt" match="alt" use="for $ref in tokenize(@target, '\s+') return substring($ref, 2)"/>
	<!-- Einfacher als in print2html da kein Variantenapparat -->
	<xsl:template match="*">
		<xsl:element name="{f:html-tag-name(.)}">
			<xsl:call-template name="generate-style"/>
			<xsl:attribute name="class" select="string-join((f:generic-classes(.),
				if (@xml:id and key('alt', @xml:id)) then 'alt' else (),
				if (@n and @part) then ('antilabe', concat('part-', @part)) else ()), ' ')"/>
			<xsl:call-template name="generate-lineno"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<!-- TODO Vereinigen mit print2html -> html-frame.xsl -->
	<xsl:template name="generate-html-frame">
		<html>
			<xsl:call-template name="html-head"/>
			<body>
				<xsl:call-template name="header"/>
				
				<main>
					<div class="main-content-container">
						<div id="main-content" class="main-content">
							<div id="main" class="print">
								<div class="print-side-column"/> <!-- 1. Spalte (1/5) bleibt erstmal frei -->
								<div class="print-center-column">  <!-- 2. Spalte (3/5) für den Inhalt -->
									<xsl:apply-templates/>
								</div>
							</div>
						</div>
					</div>
				</main>
				<xsl:call-template name="footer"/>
			</body>
		</html>
	</xsl:template>
	
	
</xsl:stylesheet>
