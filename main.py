import os

import tensorflow as tf
from tensorflow.keras import Sequential
from tensorflow.keras.layers import Dense
from keras.layers import Dense
import numpy as np


gpus = tf.config.experimental.list_physical_devices(device_type='GPU')
cpus = tf.config.experimental.list_physical_devices(device_type='CPU')
print(gpus, cpus)



def print_hi(name):

    # Define the model
    model = Sequential(
        [
            Dense(units=1, activation="relu", input_shape=[1])
        ])
    opt = tf.keras.optimizers.SGD(learning_rate=0.01)

    # Compile the model
    model.compile(optimizer='rmsprop', loss='mean_squared_error')

    # Example input and output
    # Let's assume your task is to learn the relationship y = 2x - 1
    data_size = 100  # Number of data points to generate
    X = np.array([i for i in range(data_size)], dtype=float)
    y = np.array([i*2 for i in range(data_size)], dtype=float)
    print(tf.keras.callbacks.ProgbarLogger.__init__.__doc__)
    # Train the model
    model.fit(
        X,
        y,
        epochs=300,
        validation_split=0.25,
        verbose=0,
        callbacks=[tf.keras.callbacks.ProgbarLogger(count_mode='steps')],
        shuffle=True,
        #workers=4,
        #use_multiprocessing=True
    )  # Train for 500 epochs, verbose=0 for silent training

    # Make a prediction
    print(model.predict(tf.Variable([100])))



# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    print_hi('PyCharm')

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
