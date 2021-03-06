<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xpath-default-namespace="http://www.faustedition.net/ns" version="2.0">
	<xsl:output method="text"/>
	<xsl:template match="/">
		<xsl:text>Zählung&#9;Versbeginn&#9;Textinhalt&#10;</xsl:text>
		<xsl:for-each select="//title">
			<xsl:value-of select="parent::scene/@n"/>
			<xsl:text>&#9;</xsl:text>
			<xsl:value-of select="parent::scene/@first-verse"/>
			<xsl:text>&#9;</xsl:text>
			<!-- Tab -->
			<xsl:value-of select="normalize-space(.)"/>
			<xsl:text>&#10;</xsl:text>
			<!-- Zeilenumbruch -->
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
