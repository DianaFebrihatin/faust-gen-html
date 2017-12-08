import logging
from itertools import chain

from lxml import etree

import regex as re
from lxml.builder import ElementMaker
from ruamel.yaml import YAML
from collections import defaultdict


log = logging.getLogger(__name__)

FAUST_NS = 'http://www.faustedition.net/ns'
TEI_NS = 'http://www.tei-c.org/ns/1.0'
NSMAP_ = { 'tei': TEI_NS, 'f': FAUST_NS }
NSMAP = { None: TEI_NS, 'f': FAUST_NS }

F = ElementMaker(namespace=FAUST_NS, nsmap=NSMAP)
T = ElementMaker(namespace=TEI_NS, nsmap=NSMAP)


for prefix, uri in NSMAP_.items():
    etree.register_namespace(prefix, uri)

def namespaceify(tree: etree._Element, namespace=TEI_NS):
    """Moves every element in the subtree that does _not_ have a namespace into the given namespace"""
    prefix = '{' + namespace + '}'
    for el in chain([tree], tree.iterdescendants()):
        if '{' not in el.tag:
            el.tag = prefix + el.tag


def parse_xml(text, container=None, namespace=TEI_NS):
    """parses a fragment that may contain xml elements to a tree.

    Args:
        container (str or etree._Element): container element around everything, by default 'root'
        namespace (str): Namespace URI for the parsed elements.
    """
    root_tag = container if isinstance(container, str) else 'root'
    pseudo_xml = "<{tag}>{text}</{tag}>".format_map(dict(tag=root_tag, text=text))
    xml = etree.fromstring(pseudo_xml)
    if namespace is not None:
        namespaceify(xml, namespace)
    if isinstance(container, etree._Element):
        container.text = xml.text
        container.extend(xml)
        xml = container
    return xml

def read_sigils(filename='../../../../target/faust-transcripts.xml'):
    """parses faust-transcripts.xml and returns a mapping machine-readable sigil : human-readable sigil"""
    xml = etree.parse(filename)
    idnos = xml.xpath('//f:idno[@type="faustedition" and @uri]', namespaces={'f': FAUST_NS})
    short_sigil = re.compile('faust://document/faustedition/(\S+)') # re.Regex
    return { short_sigil.match(idno.get('uri')).group(1) : idno.text  for idno in idnos }

sigils = read_sigils()

# one app line
APP = re.compile(
    r'''(?<n>\w+?)
        \[(?<replace>.*?)\]
        \{(?<insert>.*?)\}
        \s*<i>(?<reference>.*?)<\/i>
        \s*(?<lemma>.*?)\s*<i>(?<lwitness>.*?)<\/i>\]
        (?<readings>.*)''', flags=re.X)

def parse_app2norm(app_text='app2norm.txt'):
    with open(app_text, encoding='utf-8-sig') as app2norm:
        for line in app2norm:
            yield etree.Comment(line[:-1])
            match = APP.match(line)
            if match:
                log.info('Parsed: %s', line[:-1])
                parsed = defaultdict(str, match.groupdict())
                app = T.app(
                    F.replace(parsed['replace']),
                    parse_xml(parsed['insert'], F.ins(), TEI_NS),
                    T.label(parsed['reference']),
                    T.lem(parsed['lemma'], wit=parsed['lwitness']),
                    n=parsed['n']
                )
                readings = parse_readings(parsed['readings'])
                app.extend(readings)
                log.debug('-> %s', etree.tostring(app, encoding='unicode', pretty_print=False))
                yield app
            else:
                log.error("No match: %s", line[:-1])

# a reading, i.e. last part of app line
READING = re.compile(r'\s*(?<text>.*?)\s*<i>(?<references>.*?)\s*(\[(type=|Typ\s+)(?<type>\w+)\]\s*)?~?<\/i>')
HANDS = {'G', 'Gö', 'Ri', 'Re'}

def parse_readings(reading_str):
    readings = []
    carry = None
    for match in READING.finditer(reading_str):
        reading = match.groupdict()
        if 'references' in reading:
            if carry:
                wits = carry
                carry = []
            else:
                wits = []
            hands = []
            notes = []
            for ref in reading['references'].split():
                if ref in sigils:
                    wits.append(ref)
                elif ref in HANDS:
                    hands.append(ref)
                elif ref == ":":
                    carry = wits
                else:
                    notes.append(ref)

            rdg = T.rdg(reading['text'])
            if wits:
                rdg.set('wit', ' '.join(wits))
            if hands:
                rdg.set('hand', ' '.join(hands))
            if notes:
                rdg.append(T.note(' '.join(notes)))
        if 'type' in reading and reading['type']:
            rdg.set('type', reading['type'])
        readings.append(etree.Comment(match.group(0)))
        readings.append(rdg)
        log.debug(' - Reading "%s" -> %s', reading_str, etree.tostring(rdg, encoding='unicode', pretty_print=False))

    if not readings:
        log.error("No reading found in %s", reading_str)

    return readings

def app2xml(apps, filename):
    xml = F.apparatus()
    xml.extend(apps)
    with open(filename, 'wb') as outfile:
        outfile.write(etree.tostring(xml, pretty_print=True, encoding='utf-8', xml_declaration=True))

if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG, format='%(levelname)s: %(message)s')
    app = list(parse_app2norm('app2norm.txt'))
    app2xml(app, 'app2norm.xml')