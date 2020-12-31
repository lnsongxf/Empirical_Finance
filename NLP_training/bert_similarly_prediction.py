# -*- coding: utf-8 -*-
"""
Created on Thu Dec 31 12:22:01 2020

@author: Peilin Yang
"""

import numpy as np
import pandas as pd
from bert4keras.backend import keras, set_gelu, K
from bert4keras.tokenizers import Tokenizer
from bert4keras.models import build_transformer_model
from bert4keras.optimizers import Adam
from bert4keras.snippets import sequence_padding, DataGenerator
from bert4keras.snippets import open
from keras.layers import Dropout, Dense


config_path = r'C:\Users\Peilin Yang\.keras\datasets\wwm_uncased_L-24_H-1024_A-16\bert_config.json'
checkpoint_path = r'C:\Users\Peilin Yang\.keras\datasets\wwm_uncased_L-24_H-1024_A-16\bert_model.ckpt'
dict_path = r'C:\Users\Peilin Yang\.keras\datasets\wwm_uncased_L-24_H-1024_A-16\vocab.txt'


bert = build_transformer_model(
    model='bert',
    config_path=config_path,
    checkpoint_path=checkpoint_path,
    with_pool=True,
    return_keras_model=False,
)

output = Dropout(rate=0.1)(bert.model.output)
output = Dense(
    units=2, activation='softmax', kernel_initializer=bert.initializer
)(output)

model = keras.models.Model(bert.model.input, output)

model.load_weights('best_model.weights')

def load_data(filename):
    df = pd.read_csv(filename,header=0,encoding='utf8')
    f = df.values
    D = []
    # with open(filename, encoding='utf-8') as f:
    for i,l in enumerate(f):
        # print(l)
        text1, text2, label = l#.strip().split(',')
        D.append((text1, text2, int(label)))
    return D
test_data = load_data('../input/test.csv')


maxlen=64
tokenizer = Tokenizer(dict_path, do_lower_case=True)
class data_generator(DataGenerator):
    """data generator
    """
    def __iter__(self, random=False):
        batch_token_ids, batch_segment_ids, batch_labels = [], [], []
        for is_end, (text1, text2, label) in self.sample(random):
            token_ids, segment_ids = tokenizer.encode(
                text1, text2, maxlen=maxlen
            )
            batch_token_ids.append(token_ids)
            batch_segment_ids.append(segment_ids)
            batch_labels.append([label])
            if len(batch_token_ids) == self.batch_size or is_end:
                batch_token_ids = sequence_padding(batch_token_ids)
                batch_segment_ids = sequence_padding(batch_segment_ids)
                batch_labels = sequence_padding(batch_labels)
                yield [batch_token_ids, batch_segment_ids], batch_labels
                batch_token_ids, batch_segment_ids, batch_labels = [], [], []

batch_size = 8
test_generator = data_generator(test_data, batch_size)

def evaluate(data):
    total, right = 0., 0.
    for x_true, y_true in data:
        y_pred = model.predict(x_true).argmax(axis=1)
        print(y_pred,'y_pred')
        y_true = y_true[:, 0]
        print(y_true,'y_true')
        total += len(y_true)
        print(total,'total')
        right += (y_true == y_pred).sum()
        print(right,'right')
    return right / total


rightness=evaluate(test_generator)