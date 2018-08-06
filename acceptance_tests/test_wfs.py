from lxml import etree


def _test_get_feature(connection, id_, expected_value):
    answer = connection.get_xml(f'?SERVICE=WFS&VERSION=1.1.0&REQUEST=GetFeature&TYPENAME=polygons:polygons&featureId=polygons:polygons.{id_}')
    print(etree.tostring(answer, pretty_print=True))
    features = answer.findall(".//{http://www.mapserver.org/tinyows/}polygons")
    assert len(features) == 1
    feature = features[0]
    assert feature.findtext(".//{http://www.mapserver.org/tinyows/}value") == str(expected_value)


def test_get_feature(connection):
    _test_get_feature(connection, 'foo', 1)


def test_update_feature(connection):
    body = """<?xml version="1.0" encoding="UTF-8"?>
    <wfs:Transaction version="1.1.0" service="WFS"
                     xmlns:polygons="http://www.mapserver.org/tinyows/"
                     xmlns:ogc="http://www.opengis.net/ogc"
                     xmlns:wfs="http://www.opengis.net/wfs">
        <wfs:Update handle="update1" typeName="polygons:polygons">
            <wfs:Property>
                <wfs:Name>polygons:value</wfs:Name>
                <wfs:Value>2</wfs:Value>
            </wfs:Property>
            <Filter xmlns="http://www.opengis.net/ogc">
                <PropertyIsEqualTo>
                    <PropertyName>name</PropertyName>
                    <Literal>foo</Literal>
                </PropertyIsEqualTo>
            </Filter>
        </wfs:Update>
    </wfs:Transaction>
    """
    response = connection.post('', data=body, headers={'Content-Type': 'text/xml'})
    print(response)
    assert "<wfs:totalUpdated>1</wfs:totalUpdated>" in response

    _test_get_feature(connection, 'foo', 2)


def test_get_capabilities(connection):
    for _ in range(20):
        answer = connection.get_xml("?SERVICE=WFS&REQUEST=GetCapabilities&VERSION=1.1.0")
    print(etree.tostring(answer, pretty_print=True))
