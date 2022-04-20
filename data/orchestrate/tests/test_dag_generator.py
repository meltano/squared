import pytest
from airflow.models import DagBag


class TestDagGenerator:

    def test_dags_present(self):
        dag_bag = DagBag()
        assert len(dag_bag.dags) > 0, "No DAGs Generated"

    def test_no_import_errors(self):
        dag_bag = DagBag()
        assert len(dag_bag.import_errors) == 0, "Import Failures"

    def test_tags_present(self):
        dag_bag = DagBag()
        for dag in dag_bag.dags:
            error_msg = f"Tags not set for DAG {dag}"
            assert dag_bag.dags[dag].tags == ["meltano"], error_msg
