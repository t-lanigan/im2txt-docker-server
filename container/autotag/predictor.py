# This is the file that implements a flask server to do inferences. It's the file that you will modify to
# implement the scoring for your own algorithm.
from __future__ import print_function
import os
import json
import StringIO
import flask
import pandas as pd
from save_load_fns import *

# Global locations.
prefix = '/opt/ml/'
model_path = os.path.join(prefix, 'model')

class ScoringService(object):
    """A singleton for holding the model. 

    This class simply loads the models and holds them.
    It has a predict function that does a prediction based on the model and the input data.
    """

    models = {}  # Where we keep the model when it's loaded

    # Load the models in the model folder.
    model_names = [f for f in os.listdir(model_path) if f != '.DS_Store']
    for model_name in model_names:
        owner_name = model_name.split('_predictor')[0]
        load_path = model_path+'/'+model_name
        models[owner_name] = load_object(load_path)

    @classmethod
    def get_model(cls):
        """Get the model objects for this instance"""
        return cls.models


    @classmethod
    def predict(cls, input_data):
        """For the input, do the predictions and return them.

        Args:
            input_data (a Pandas DataFrame): The data on which to do the predictions. There will be
                one prediction per row."""
        
        # TODO: Need a better way to do this..
        owner_name = input_data['owner_name'].unique()[0]
        clf = cls.get_model()[owner_name]

        return {k:v for k, v in zip(clf.label_cols, clf.predict_proba(input_data['text'])[0])}


# Starts the flask app for serving predictions
app = flask.Flask(__name__)


@app.route('/am-i-up', methods=['GET'])
def am_i_up():
    """Determine if the container is working and healthy. In this sample container, we declare
    it healthy if we can load the models successfully."""
    return ping()


@app.route('/ping', methods=['GET'])
def ping():
    """Determine if the container is working and healthy. In this sample container, we declare
    it healthy if we can load the model successfully."""
    health = ScoringService.get_model() is not {}  # You can insert a health check here
    status = 200 if health else 404
    return flask.Response(response='ping!', status=status, mimetype='application/json')


@app.route('/invocations', methods=['POST'])
def transformation():
    """Do an inference on a single batch of data. In this sample server, we take data as CSV, convert
    it to a pandas data frame for internal use and then convert the predictions back to CSV (which really
    just means one prediction per line, since there's a single column.
    """
    request_type = flask.request.content_type
    print(request_type)
    # Convert from JSON to pandas
    if request_type == 'application/json':
        data = flask.request.data.decode('utf-8')
        s = StringIO.StringIO(data)
        data = pd.read_json(s)
    else:
        return flask.Response(response='This predictor only supports JSON data, Request:'.format(request_type),
                              status=415,
                              mimetype='text/plain')

    print('Invoked with {} records'.format(data.shape[0]))

    # Do the prediction
    predictions = ScoringService.predict(data)

    return flask.Response(response=json.dumps(predictions), status=200, mimetype='application/json')
