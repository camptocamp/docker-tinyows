from lxml import etree


def _test_get_feature(connection, id_, expected_value):
    answer = connection.get_xml(
        f"?SERVICE=WFS&VERSION=1.1.0&REQUEST=GetFeature&TYPENAME=polygons:polygons&featureId=polygons:polygons.{id_}"
    )
    print(etree.tostring(answer, pretty_print=True))
    features = answer.findall(".//{http://www.mapserver.org/tinyows/}polygons")
    assert len(features) == 1
    feature = features[0]
    assert feature.findtext(".//{http://www.mapserver.org/tinyows/}value") == str(expected_value)


def test_get_feature(connection):
    _test_get_feature(connection, "foo", 1)


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
                <PropertyIsEqualTo>                    <PropertyName>name</PropertyName>
                    <Literal>foo</Literal>
                </PropertyIsEqualTo>
            </Filter>
        </wfs:Update>
    </wfs:Transaction>
    """
    response = connection.post("", data=body, headers={"Content-Type": "text/xml"})
    print(response)
    assert "<wfs:totalUpdated>1</wfs:totalUpdated>" in response

    _test_get_feature(connection, "foo", 2)


def test_get_capabilities(connection):
    answer = connection.get_xml("?SERVICE=WFS&REQUEST=GetCapabilities&VERSION=1.1.0")
    root = answer.getroot()

    # Vérifier l'élément racine
    assert root.tag == "{http://www.opengis.net/wfs}WFS_Capabilities"
    assert root.get("version") == "1.1.0"

    # Vérifier le titre
    title_elem = root.find(".//{http://www.opengis.net/ows}Title")
    assert title_elem is not None
    assert title_elem.text == "TinyOWS Server - Demo Service"

    # Vérifier les opérations
    operations = root.findall(".//{http://www.opengis.net/ows}Operation")
    operation_names = {op.get("name") for op in operations}
    expected_operations = {"GetCapabilities", "DescribeFeatureType", "GetFeature", "Transaction"}
    assert operation_names == expected_operations

    # Vérifier le feature type polygons:polygons
    feature_type_list = root.find(".//{http://www.opengis.net/wfs}FeatureTypeList")
    assert feature_type_list is not None

    feature_types = feature_type_list.findall(".//{http://www.opengis.net/wfs}FeatureType")
    assert len(feature_types) >= 1

    # Trouver le feature type polygons:polygons
    polygons_found = False
    for ft in feature_types:
        name_elem = ft.find("{http://www.opengis.net/wfs}Name")
        if name_elem is not None and name_elem.text == "polygons:polygons":
            polygons_found = True

            # Vérifier le titre
            title_elem = ft.find("{http://www.opengis.net/wfs}Title")
            assert title_elem is not None
            assert title_elem.text == "Polygons"

            # Vérifier les SRS supportés
            default_srs = ft.find("{http://www.opengis.net/wfs}DefaultSRS")
            assert default_srs is not None
            assert default_srs.text == "urn:ogc:def:crs:EPSG::4326"

            # Vérifier les autres SRS (chercher OtherSRS ou OtherCRS)
            other_srs_elements = ft.findall("{http://www.opengis.net/wfs}OtherSRS")
            if not other_srs_elements:
                other_srs_elements = ft.findall("{http://www.opengis.net/wfs}OtherCRS")

            other_srs = {crs.text for crs in other_srs_elements}

            # SRS attendus selon la configuration standard de tinyows
            expected_srs = {
                "urn:ogc:def:crs:EPSG::4326",
            }

            # Vérifier que tous les SRS attendus sont présents
            for srs in expected_srs:
                if srs == default_srs.text:
                    continue
                assert srs in other_srs, f"SRS {srs} manquant dans OtherSRS/OtherCRS"

            # Vérifier la bounding box
            bbox = ft.find(".//{http://www.opengis.net/ows}WGS84BoundingBox")
            assert bbox is not None
            lower_corner = bbox.find("{http://www.opengis.net/ows}LowerCorner")
            upper_corner = bbox.find("{http://www.opengis.net/ows}UpperCorner")
            assert lower_corner is not None
            assert upper_corner is not None

            break

    assert polygons_found, "Feature type polygons:polygons non trouvé dans GetCapabilities"
