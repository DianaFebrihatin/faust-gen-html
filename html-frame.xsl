<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:f="http://www.faustedition.net/ns"
	exclude-result-prefixes="xs f"
	version="2.0">
	
	<xsl:param name="title">Digitale Faustedition</xsl:param>
	<xsl:param name="edition">..</xsl:param>
	<xsl:param name="assets" select="$edition"/>
	<xsl:param name="debug" select="false()"/>
	<xsl:param name="headerAdditions"/>
	
	<xsl:template name="html-head">
		<xsl:param name="title" select="$title"/>
		<head>
			<meta charset='utf-8'/>
			
			<script type="text/javascript" src="{$assets}/js/faust_common.js"/>
			<script src="{$assets}/js/faust_print_interaction.js"/>			
			<link href="//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css" rel="stylesheet"/>
			<link rel="stylesheet" href="{$assets}/css/document-text.css"/>
			<link rel="stylesheet" href="{$assets}/css/document-transcript.css"/>
			<link rel="stylesheet" href="{$assets}/css/document-transcript-highlight-hands.css"/>
			<link rel="stylesheet" href="{$assets}/css/document-transcript-interaction.css"/>
			<link rel="stylesheet" href="{$assets}/css/pure-min.css"/>
			<link rel="stylesheet" href="{$assets}/css/pure-custom.css"/>
			<link rel="stylesheet" href="{$assets}/css/basic_layout.css"/>
			<link rel="stylesheet" href="{$assets}/css/textual-transcript.css"/>
			<script><xsl:text>window.addEventListener("DOMContentLoaded", function(){addPrintInteraction("../");});</xsl:text></script> 
			
			<xsl:copy-of select="$headerAdditions"/>
		</head>
		
	</xsl:template>
	
	<xsl:template name="header">
		<xsl:param name="breadcrumbs" tunnel="yes"/>
    <header>
      <div class="pure-g-r">
        <div class="logo pure-u-1-3">
          <a href="{$edition}/" title="Faustedition"><img src="{$assets}/img/faustlogo.svg" alt="Faustedition"/></a>
        </div>
        <div class="breadcrumbs pure-u-1-3 pure-center pure-fade-50">
					<small id="breadcrumbs">
						<xsl:copy-of select="$breadcrumbs"/>
					</small>
        </div>
        <div class="pure-u-1-3">
        <nav class="pure-menu pure-menu-open pure-menu-horizontal pure-right">
					<ul>
						<li><a href="{$edition}/archives.php">Archiv</a></li>
						<li><a href="{$edition}/chessboard_overview.php">Genese</a></li>
						<li><a href="{$edition}/print/text.html">Text</a></li>
					</ul>                                                        
				</nav>
				</div>
			</div>
		</header>
	</xsl:template>
	
	<xsl:template name="footer">
		<footer>
			<div class='pure-g-r'>
				<div class="pure-u-1-2 pure-fade-50">
					<b>Digitale Faust-Edition</b>
					<xsl:if test="$debug">
						<xsl:text> • </xsl:text>
						<mark><a href="./index.html">
							Generiert: <xsl:value-of select="current-dateTime()"/>
						</a></mark>
					</xsl:if>
				</div>
				<div class="pure-u-1-2 pure-right pure-fade-50">
					<a href="{$edition}/help.php">Hilfe</a>
					<xsl:text> </xsl:text>
					<a href="{$edition}/contact.php">Kontakt</a>
					<xsl:text> </xsl:text>
					<a href="{$edition}/imprint.php">Impressum</a>
					<xsl:text> </xsl:text>
					<a href="{$edition}/project.php">Projekt</a>
				</div>
			</div>
		</footer>
	</xsl:template>
	
		
	
</xsl:stylesheet>