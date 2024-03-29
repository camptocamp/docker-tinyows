"""
Common fixtures for every tests.
"""

import logging

import pytest
import sqlalchemy
import sqlalchemy.orm
import transaction
from c2cwsgiutils.acceptance import utils
from c2cwsgiutils.acceptance.composition import Composition
from c2cwsgiutils.acceptance.connection import Connection
from zope.sqlalchemy import register

BASE_URL = "http://" + utils.DOCKER_GATEWAY + ":8380/"
LOG = logging.getLogger(__name__)


def wait_db(db_engine):
    def what():
        session = _session(db_engine)
        try:
            (count,) = session.execute("SELECT count(*) FROM polygons").fetchone()
            if count > 0:
                LOG.info("DB connected and filled")
                return True
            else:
                LOG.info("DB connected but empty")
                return False
        finally:
            transaction.abort()

    utils.retry_timeout(what)


@pytest.fixture(scope="session")
def composition(request):
    """
    Fixture that start/stop the Docker composition used for all the tests.
    """
    result = Composition(request, "tinyows", "docker-compose.yml")
    return result


@pytest.fixture(scope="session")
def db_engine(composition):
    engine = sqlalchemy.create_engine(f"postgresql://www-data:www-data@{utils.DOCKER_GATEWAY}:15432/test")
    wait_db(engine)
    return engine


@pytest.fixture
def db(db_engine, request):
    session = _session(db_engine)
    request.addfinalizer(transaction.abort)
    return session


@pytest.fixture
def connection(composition, db):
    """
    Fixture that returns a connection to a running batch container.
    """
    return Connection(BASE_URL, "http://localhost")


def _session(db_engine):
    factory = sqlalchemy.orm.sessionmaker(bind=db_engine)
    register(factory)
    return sqlalchemy.orm.scoped_session(factory)
