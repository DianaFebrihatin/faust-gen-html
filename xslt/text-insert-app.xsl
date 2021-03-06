<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:f="http://www.faustedition.net/ns"
    exclude-result-prefixes="xs f" 
    version="2.0">
    
    <xsl:import href="utils.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <xsl:output method="xml" indent="no"/>
    <xsl:strip-space elements="app choice subst"/>
    
    <xsl:variable name="text" select="/"/>
       
    <!-- The apparatus specification in XML form -->
    <xsl:variable name="spec" select="doc('../text/app12norm_special-cases.xml'),
                                      doc('../text/app1norm.xml'),
                                      doc('../text/app2norm.xml')"/>

    <xsl:template match="/">
        <xsl:variable name="inserted-apps">
            <xsl:apply-templates/>
        </xsl:variable>        
        <xsl:variable name="pass2"><xsl:apply-templates mode="pass2" select="$inserted-apps"/></xsl:variable>
        <xsl:apply-templates mode="pass3" select="$pass2"/>
        <!--<xsl:result-document href="/tmp/pass1.xml" indent="yes"><xsl:copy-of select="$inserted-apps"/></xsl:result-document>
        <xsl:result-document href="/tmp/pass2.xml" indent="yes"><xsl:copy-of select="$pass2"/></xsl:result-document>-->
    </xsl:template>

    <!-- base function for the id calculations, based in an app's f:ins -->
    <xsl:function name="f:ins-id" as="xs:string">
        <xsl:param name="prefix" as="xs:string"/>        
        <xsl:param name="ins" as="element(f:ins)"/>
        <xsl:variable name="parts" as="item()*">
            <xsl:for-each select="$ins"><!-- focus -->
                <xsl:variable name="strrep" select="replace(lower-case(.), '\W+', '')"/>
                <xsl:value-of select="$prefix"/>
                <xsl:value-of select="@n, @id"/>
                <xsl:choose>
                    <xsl:when test="$strrep != ''"><xsl:value-of select="$strrep"/></xsl:when>
                    <xsl:when test="@place"><xsl:value-of select="@place"/></xsl:when>                    
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="replace(string-join($parts, '.'), '[^a-z0-9._-]+', '')"/>
    </xsl:function>
    
    <!-- calculates an id for the seg corresponding to an app's f:ins -->
    <xsl:function name="f:seg-id" as="xs:string">
        <xsl:param name="ins" as="element(f:ins)"/>
        <xsl:value-of select="f:ins-id('seg', $ins)"/>
    </xsl:function>
    
    <!-- calculates an id for an app -->
    <xsl:function name="f:app-id" as="xs:string">
        <xsl:param name="for" as="node()"/>
        <xsl:variable name="app" select="$for/ancestor-or-self::app[1]"/>
        <xsl:variable name="ins" select="$app/f:ins[1]"/>
        <xsl:value-of select="f:ins-id('app', $ins)"/>
    </xsl:function>
    
    
    <!-- lines for which an apparatus entry exists -->
    <xsl:template match="*[f:hasvars(.)][tokenize(@n, '\s+') = $spec//f:ins/@n] | *[@xml:id = $spec//f:ins/@id]">
        <xsl:variable name="current-line" select="tokenize(@n, '\s+')"/>
        <xsl:variable name="current-ins" select="$spec//f:ins[@n = $current-line or @id = current()/@xml:id]"/>
        <xsl:variable name="apps" select="$spec//$current-ins[not(@place=('before', 'after'))]/.." as="element()*"/>
        <xsl:for-each select="$current-ins[@place='before']">
            <xsl:call-template name="create-app-within-new-content">
                <xsl:with-param name="new-content" select="node()"/>
                <xsl:with-param name="apps" select=".."/>
                <xsl:with-param name="id" select="f:seg-id(.)"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:copy copy-namespaces="no">
            <xsl:if test="$current-ins[@place='only-app'] and not(@xml:id)">
                <xsl:attribute name="xml:id" select="generate-id(.)"/>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$current-ins[@place='attributes']">
                    <xsl:variable name="ins-attrs" select="$current-ins[@place='attributes']/*/@*"/>
                    <xsl:copy-of select="$ins-attrs[data(.) != '']"/>
                    <!-- attributes from the lg that are _not_ in the apparatus -->
                    <xsl:apply-templates select="@*[not(name() = (for $attr in $ins-attrs return name($attr)))]" mode="#current"/>
                    <xsl:call-template name="create-app-note">
                        <xsl:with-param name="apps" select="$current-ins[@place='attributes']/.."/>
                    </xsl:call-template>                    
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@*" mode="with-app"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="node()" mode="with-app">
                <xsl:with-param name="apps" select="$apps" tunnel="yes"/>
                <xsl:with-param name="current-line" select="$current-line" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:call-template name="create-app-note">
                <xsl:with-param name="apps" select="$apps"/>
            </xsl:call-template>
        </xsl:copy>
        <xsl:for-each select="$current-ins[@place='after']">
            <xsl:call-template name="create-app-within-new-content">
                <xsl:with-param name="new-content" select="node()"/>
                <xsl:with-param name="apps" select=".."/>
                <xsl:with-param name="id" select="f:seg-id(.)"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="create-app-within-new-content">
        <xsl:param name="new-content" required="yes"/>
        <xsl:param name="apps" required="yes"/>
        <xsl:param name="id"/>        
        <xsl:variable name="processed-new-content" as="node()*">
            <xsl:apply-templates select="$new-content"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$processed-new-content[f:hasvars(.)]|$processed-new-content[self::milestone]">
                <xsl:for-each select="$processed-new-content">
                    <xsl:copy copy-namespaces="no">
                        <xsl:apply-templates select="@*"/>
                        <xsl:if test="$id">
                            <xsl:attribute name="xml:id" select="$id"/>
                        </xsl:if>
                        <xsl:call-template name="create-app-note"><xsl:with-param name="apps" select="$apps"/></xsl:call-template>
                        <xsl:apply-templates select="node()"/>
                    </xsl:copy>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="create-app-note"><xsl:with-param name="apps" select="$apps"/></xsl:call-template>
                <xsl:apply-templates select="$processed-new-content"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- creates the note[@type="textcrit"] for the given app element -->    
    <xsl:template name="create-app-note">
        <xsl:param name="apps"/>
        <xsl:for-each select="$apps">
            <note type="textcrit">
                <xsl:attribute name="xml:id" select="f:app-id(.)"/>
                <xsl:copy-of select="ref" copy-namespaces="no"/>
                <app>
                    <xsl:attribute name="from" separator=" " select="(
                        for $ins in f:ins[not(@place='only-app')] return concat('#', f:seg-id($ins)),
                        for $ins in f:ins[@place='only-app'] return
                            for $el in $text//*[@n = $ins/@n and f:hasvars(.)] return concat('#', generate-id($el))
                        )"/>                    
                    <xsl:apply-templates select="lem" mode="app"/>
                    <xsl:apply-templates select="rdg" mode="app"/>
                    <xsl:variable name="types" select="distinct-values(for $type in rdg/@type return tokenize($type, '\s+'))"/>
                    <xsl:choose>
                        <xsl:when test="count($types) >= 2">
                            <note type="type">
                                <xsl:text>  </xsl:text>
                                <xsl:text>(</xsl:text>
                                <xsl:for-each select="$types">
                                    <ref target="faust://app/{.}">
                                        <xsl:value-of select="f:format-rdg-type(.)"/>
                                    </ref>
                                    <xsl:if test="position() != last()">, </xsl:if>
                                </xsl:for-each>
                                <xsl:text>)</xsl:text>
                            </note>
                        </xsl:when>
                        <xsl:when test="count($types) = 1">
                            <note type="type">
                                <xsl:text>  </xsl:text>
                                <ref target="faust://app/{$types}">
                                    <xsl:value-of select="concat('(', f:format-rdg-type($types), ')')"/>
                                </ref>
                            </note>
                        </xsl:when>
                    </xsl:choose>                    
                </app>
            </note>
        </xsl:for-each>
    </xsl:template>
    
    <!-- 
        esp. for the printed edition, we create a short sigil that leaves out the leading arabic number
        and uses superscript indexes for sigil parts that are preceded by .
        
        This function creates a TEI representation.
    -->
    <xsl:variable name="sigil-preprocessing">
        <f:sigil orig="C.1 12">C.1</f:sigil>
        <f:sigil orig="C.3 12">C.3</f:sigil>
        <f:sigil orig="C.1 4">C.1</f:sigil>
        <f:sigil orig="C.2α 4">C.2α</f:sigil>
        <f:sigil orig="C.3 4">C.3</f:sigil>
    </xsl:variable>
    <xsl:function name="f:short-sigil" as="item()*">
        <xsl:param name="sigil"/>
        <xsl:variable name="sigil-prepped" select="if ($sigil-preprocessing/f:sigil/@orig = $sigil)
            then $sigil-preprocessing/f:sigil[@orig = $sigil]/text()
            else $sigil"/>
        <xsl:variable name="noprefix" select="replace($sigil-prepped, '^\d+\s*', '')"/>
        <xsl:analyze-string select="$noprefix" regex="\.(\S+)">
            <xsl:matching-substring>
                <hi rend="superscript">
                    <xsl:value-of select="regex-group(1)"/>
                </hi>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy/>
            </xsl:non-matching-substring>            
        </xsl:analyze-string>
    </xsl:function>
    
    <!-- We add a <wit> element with the sigil as it should be rendered at the end 
         unless there already are <wit> children -->
    <xsl:template mode="app" match="rdg[@wit and not(descendant::wit)]|lem[@wit and not(descendant::wit)]">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="#current" select="@*, node()"/>
            <xsl:text> </xsl:text>
            <xsl:call-template name="wit"><xsl:with-param name="wits" select="@wit"/></xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <!-- <wit> elements get a sigil as it should be rendered at the end -->
    <xsl:template match="wit" name="wit" mode="app">        
        <xsl:param name="wits" select="if (@wit) then @wit else ."/>
        <xsl:for-each select="tokenize($wits, '\s+')">            
            <xsl:variable name="uri" select="if (starts-with(., 'faust://')) then . else concat('faust://document/faustedition/', .)"/>
            <xsl:variable name="sigil" select="$idmap//f:idno[@uri=$uri]"/>
            <xsl:text> </xsl:text>
            <wit wit="{$uri}">
                <xsl:sequence select="f:short-sigil($sigil)"/>                    
            </wit>
            <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>            
        </xsl:for-each>
    </xsl:template>
    
    <!-- <note> elements that just surround <wit>s and whitespace are superflous -->
    <xsl:template match="note[wit and count(node()) = 1 or (not(* except wit) and matches(string-join(text(), ''), '^\s*$'))]" mode="app">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="ref[starts-with(@target, 'faust://bibliography/')][normalize-space(.) = '']" mode="app">
        <xsl:variable name="citation" select="normalize-space(data(f:cite(@target, false())))"/>
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"/>
            <xsl:choose>
                <xsl:when test="matches($citation, '.*\.\S')">
                    <xsl:sequence select="f:short-sigil($citation)"></xsl:sequence>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$citation"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="*[milestone[@unit='refline'][@n=$spec//f:ins/@n]]">
        <xsl:variable name="ns" select="milestone[@unit='refline']/@n"/>
        <xsl:variable name="apps" select="$spec//app[f:ins/@n = $ns]"/>
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates mode="with-refline-app">
                <xsl:with-param name="apps" tunnel="yes" select="$apps"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template mode="with-refline-app" match="text()" priority="1">
        <xsl:param name="apps" tunnel="yes"/>
        <xsl:variable name="current-milestone" select="preceding::milestone[@unit='refline'][1]"/>
        <xsl:variable name="current-refline" select="data($current-milestone/@n)"/>
        <xsl:variable name="current-apps" select="$apps[f:ins[@n=$current-refline]]"/>
        <xsl:apply-templates mode="with-app" select=".">
            <xsl:with-param name="apps" tunnel="yes" select="$current-apps"/>
            <xsl:with-param name="current-line" tunnel="yes" select="$current-refline"/>
            <xsl:with-param name="insert-app-immediately" tunnel="yes" select="true()"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <!-- the with-app mode is chosen for content where we know there is a lemma inside somewhere -->
    <!-- 
        This processes a relevant text node: It searches the text content for any lem inside, and
        if it finds one, it encloses it with <seg> and adds an apparatus note.
    -->
    <xsl:template mode="with-app" match="text()" priority="1">
        <xsl:param name="apps" tunnel="yes"/>
        <xsl:param name="current-line" tunnel="yes"/>
        <xsl:param name="insert-app-immediately" tunnel="yes" select="false()"/>
        <xsl:variable name="replace-strings" select="for $repl in $apps/f:replace return replace(data($repl), '([\]^$().*+?\[])', '\\$1')" as="item()*"/>       
        <xsl:variable name="rs-left-boundary" select="for $repl in $replace-strings return
                                                        if (matches($repl, '^\w')) then concat('\b', $repl) else $repl"/>
        <xsl:variable name="rs-right-boundary" select="for $repl in $rs-left-boundary return 
                                                        if (matches($repl, '\w$')) then concat($repl, '\b') else $repl"/>
        <xsl:variable name="re" select="string-join($rs-right-boundary, '|')"/> 
<!--        <xsl:message select="concat('searching for /', $re, '/ in ', string-join($apps/@n, ', '))"/>-->
        <xsl:choose>
            <xsl:when test="string-join($replace-strings, '') = ''">
                <xsl:copy/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="wsp-normalized" select="f:contract-space(.)"/>
                <xsl:analyze-string select="$wsp-normalized" regex="{$re}" flags="!">
                    <xsl:matching-substring>
                        <xsl:variable name="current-match" select="."/>
                        <xsl:variable name="current-replaces" select="$apps//f:replace[data(.) = $current-match and @n=$current-line]"/>
                        <xsl:variable name="current-replace" as="element()">
                            <xsl:choose>
                                <xsl:when test="count($current-replaces) > 1">
                                    <xsl:sequence select="($current-replaces)[position()=last()]"/>
                                    <xsl:message>ERROR: Multiple app entries: <xsl:copy-of select="$current-replaces"/></xsl:message>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="$current-replaces"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>                        
                        <xsl:variable name="current-ins" select="$current-replace/following-sibling::f:ins[1]"/>
                        <xsl:variable name="current-apps" select="$current-replace/.."/>
                        <xsl:if test="count($current-apps) > 1">
                            <xsl:message select="concat('ERROR: Multiple app entries for ', $current-match, ' in ', $current-line,
                                ': ', string-join(for $app in $apps return concat($app, ' @ ', document-uri(root($app))), '; '))"/>
                        </xsl:if>
                        <xsl:variable name="current-app" select="$current-apps[1]"/>
                        <seg type="lem">
                            <xsl:attribute name="xml:id" select="f:seg-id($current-ins)"/>
                            <xsl:copy-of select="$current-ins/node()" copy-namespaces="no"/>
                        </seg>
                        <xsl:if test="$insert-app-immediately">
                            <xsl:call-template name="create-app-note">
                                <xsl:with-param name="apps" select="$current-apps"/>
                            </xsl:call-template>                            
                        </xsl:if>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:copy copy-namespaces="no"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="*[@xml:id]" mode="with-app">
        <xsl:param name="apps" tunnel="yes"/>
        <xsl:param name="current-line" tunnel="yes"/>
        <xsl:variable name="repl" select="$apps//f:repl[@element-id=current()/@xml:id]"/>
        <xsl:choose>
            <xsl:when test="$repl">
                <xsl:variable name="ins" select="$repl/following-sibling::f:ins[1]"/>
                <seg type="lem">
                    <xsl:attribute name="xml:id" select="f:seg-id($ins)"/>
                    <xsl:apply-templates select="$ins/node()" mode="#current"/>
                </seg>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template mode="app" match="@wit">
        <xsl:attribute name="wit" select="
            for $wit in tokenize(., '\s+')
                return concat('faust://document/faustedition/', $wit)"/>
    </xsl:template>
    
    <xsl:template mode="app" match="font">
        <xsl:choose>
            <xsl:when test="@char-space='+2'">
                <hi rend="letter-spaced">
                    <xsl:apply-templates mode="#current"/>
                </hi>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>ERROR: Invalid font element in apparatus. <xsl:copy-of select="."/></xsl:message>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template mode="app" match="tab"><xsl:text> </xsl:text></xsl:template>
    <xsl:template mode="app" match="br"><lb/></xsl:template>

    <!-- f:ins[@place='enclosing-lg'] allows to set attributes on the lg enclosing a specific verse -->
    <xsl:template match="lg[*[@n = $spec//f:ins[@place='enclosing-lg']/@n]]">
        <xsl:variable name="insert-element" select="$spec//f:ins[@place='enclosing-lg'][@n = current()/l/@n]"/>
        <xsl:variable name="app-spec" select="$insert-element/.."/>
        <xsl:choose>
            <xsl:when test="$insert-element/lg">
                <xsl:copy copy-namespaces="no">
                    <!-- attributes from the apparatus -->
                    <xsl:copy-of select="$insert-element/lg/@*[data(.) != '']"/>
                    <!-- attributes from the lg that are _not_ in the apparatus -->
                    <xsl:apply-templates select="@*[not(name() = (for $attr in $insert-element/*/@* return name($attr)))]" mode="#current"/>
                    <!-- id -->
                    <xsl:attribute name="xml:id" select="f:seg-id($insert-element[1])"/>
                    <!-- text-critical note -->            
                    <xsl:call-template name="create-app-within-new-content">
                        <xsl:with-param name="apps" select="$app-spec"/>
                        <xsl:with-param name="new-content" select="(*)[1]"/>                
                    </xsl:call-template>
                    <!-- Everything else -->
                    <xsl:apply-templates select="node() except (*)[1]" mode="#current"/>
                </xsl:copy>                
            </xsl:when>
            <xsl:when test="$insert-element/f:remove-lg">
                <!-- text-critical note -->
                <xsl:call-template name="create-app-within-new-content">
                    <xsl:with-param name="apps" select="$app-spec"/>
                    <xsl:with-param name="new-content" select="(*)[1]"/>                    
                </xsl:call-template>
                <!-- Everything else -->
                <xsl:apply-templates select="node() except (*)[1]" mode="#current"/>                
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>ERROR: Did not understand lg-relevant command <xsl:copy-of select="$insert-element"/></xsl:message>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- 
        To split an existing lg, insert a <milestone unit='lg'/> at the break point. This template
        takes care of actually performing the split. The apparatus has already been generated when
        inserting the milestone. Attributes except @unit are copied from the milestone to the lg.
    -->
    <xsl:template mode="pass2" match="lg[milestone[@unit='lg']]" name="build-lgs">
        <xsl:param name="original-lg" select="."/>
        <xsl:param name="lines-to-regroup" select="node()"/>
        <xsl:for-each-group select="$lines-to-regroup" group-starting-with="milestone[@unit='lg']">
            <lg>
                <xsl:choose>
                    <xsl:when test="self::milestone[@unit='lg']">
                        <xsl:copy-of select="@* except @unit"/>
                        <xsl:variable name="note-textcrit" select="self::milestone[@unit='lg']/*"/>
                        <xsl:for-each select="current-group()[2]">
                            <xsl:copy>
                                <xsl:apply-templates mode="#current" select="@*"/>
                                <xsl:copy-of select="$note-textcrit"/>
                                <xsl:apply-templates mode="#current" select="node()"/>
                            </xsl:copy>
                        </xsl:for-each>
                        <xsl:apply-templates mode="#current" select="subsequence(current-group(), 3)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$original-lg/@*"/>
                        <xsl:apply-templates mode="#current" select="current-group()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </lg>
        </xsl:for-each-group>
    </xsl:template>
    
    <!-- 
        To create lgs out of thin air, insert <milestone unit="@lg"/> in the appropriate places.
        This template takes the <sp> as outer boundary.
    -->
    <xsl:template mode="pass2" match="sp[milestone[@unit='lg']]">
        <xsl:copy copy-namespaces="no">
            <!-- collect children up to the first l -->
            <xsl:variable name="not-to-group" select="node()[not(preceding-sibling::l | self::l | self::milestone[@unit='lg'])]"/>
            <xsl:copy-of select="@*, $not-to-group" copy-namespaces="no"/>
            <xsl:call-template name="build-lgs">
                <xsl:with-param name="original-lg" select="()"/>
                <xsl:with-param name="lines-to-regroup" select="node() except $not-to-group"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>
    
    <!-- Mark base witnesses. We need to do this when the wits are already inserted -->
    <xsl:function name="f:is-base-witness" as="xs:boolean">
        <xsl:param name="context"/>
        <xsl:param name="uri"/>
        <xsl:variable name="lastShift" select="$context/preceding::witStart[1]" as="element()*"/>
        <xsl:if test="$lastShift">
            <xsl:message>
                <xsl:copy-of select="$lastShift"/>
            </xsl:message>
        </xsl:if>
        <xsl:variable name="baseUri" select="if ($lastShift) then $lastShift else 'faust://document/faustedition/A'"/>
        <xsl:value-of select="$uri = $baseUri"/>
    </xsl:function>
    
    <xsl:template mode="pass2" match="wit">
        <xsl:variable name="lastShift" select="preceding::witStart[1]"/>
        <xsl:variable name="currentBase" select="if ($lastShift) then $lastShift/@wit else 'faust://document/faustedition/A'"/>
        <xsl:copy>            
            <xsl:if test="$currentBase = @wit">
                <xsl:attribute name="f:is-base">true</xsl:attribute>
            </xsl:if>
            <xsl:copy-of select="@* except f:is-base"/>
            <xsl:apply-templates mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- 
        Find and mark abbreviations in the apparatus.  
    -->
    <xsl:template mode="pass3" match="app//text()" priority="1">
        <xsl:variable name="abbrs" select="doc('../text/abbreviations.xml')//abbr"/>
        <xsl:variable name="partial-res" select="for $a in $abbrs return concat('\b', data($a), '(\.|\b)')"/>        
        <xsl:variable name="re" select="string-join($partial-res, '|')"/>        
        <xsl:analyze-string select="." regex="{$re}" flags="!">
            <xsl:matching-substring>
                <!-- We always want them without trailing . -->
                <xsl:variable name="without-dot" select="replace(., '\.$', '')"/>
                <abbr><xsl:value-of select="$without-dot"/></abbr>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:copy/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>    
    
    <!-- 
        List of witnesses.
    -->
    <xsl:template mode="pass2" match="sourceDesc">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="#current" select="@*"/>
            <listWit>
                <xsl:for-each-group select="for $wit in (//lem|//rdg)/@wit return tokenize($wit, '\s+')" group-by=".">
                    <xsl:variable name="uri" select="current-grouping-key()"/>                    
                    <witness corresp="{$uri}"><xsl:value-of select="$idmap//f:idno[@uri=$uri]/../f:idno[@type='faustedition']"/></witness>                    
                </xsl:for-each-group>
            </listWit>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Removing duplicates -->
    <!-- Phase 1: The antilabe case.  -->
    <xsl:template mode="pass2" match="note[@type='textcrit']">
        <xsl:variable name="current-id" select="@xml:id"/>
        <xsl:variable name="fromrefs" select="for $fromref in tokenize(app/@from, '\s+') return replace($fromref, '^#', '')" as="item()*"/>
        <xsl:choose>
            <!-- no duplicate: keep -->
            <xsl:when test="count(//note[@xml:id=$current-id]) = 1">
                <xsl:next-match/>               
            </xsl:when>
            <!-- references sth in the current line: keep -->
            <xsl:when test="ancestor::*[f:hasvars(.)]//seg[@xml:id = $fromrefs]">
                <xsl:next-match/>
            </xsl:when>
            <!-- something else referenced from the current app: drop here, keep there -->
            <xsl:when test="//seg[@xml:id = $fromrefs] and ancestor::*[f:hasvars(.)]"/>
            <!-- otherwise keep, just to be sure -->
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Phase 2: drop all remaining duplicates. Only the first instance is kept. -->
    <xsl:template mode="pass3" match="note[@type='textcrit']">
        <xsl:variable name="current-id" select="@xml:id"/>
        <xsl:if test="not(preceding::note[@type='textcrit'][@xml:id=$current-id])">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <!-- if a seg is found inside a f:ins seg, we remove the outer seg and copy its attributes to the inner one
         This allows situations in which the replace string must be artificially longer to ensure unambiguity
    -->
    <xsl:template mode="pass3" match="seg[@type='lem'][seg]">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>    
    <xsl:template mode="pass3" match="seg[@type='lem']//seg">
        <xsl:copy>
            <xsl:apply-templates select="ancestor::seg[1]/@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- Pass through unchanged everything else. -->
    <xsl:template match="node() | @*" mode="#default pass2 pass3 app remove-notes with-app with-refline-app">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates mode="#current" select="@*, node()"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
