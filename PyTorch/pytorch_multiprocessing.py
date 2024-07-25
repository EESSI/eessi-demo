# This example is based on the code given at
# https://www.geeksforgeeks.org/multiprocessing-in-python-and-pytorch/
# (as of 18 July 2024)

# Import the necessary libraries 
import torch 
import torch.nn as nn 
import torch.multiprocessing as mp 


# Define the training function 
def train(model, X, Y): 
	# Define the learning rate, number of iterations, and loss function 
	learning_rate = 0.01
	n_iters = 100
	loss = nn.MSELoss() 
	optimizer = torch.optim.SGD(model.parameters(), lr=learning_rate) 

	# Loop through the specified number of iterations 
	for epoch in range(n_iters): 
		# Make predictions using the model 
		y_predicted = model(X) 

		# Calculate the loss 
		l = loss(Y, y_predicted) 

		# Backpropagate the loss to update the model parameters 
		l.backward() 
		optimizer.step() 
		optimizer.zero_grad() 

		# Print the current loss and weights every 10 epochs 
		if epoch % 10 == 0: 
			[w, b] = model.parameters() 
			print( 
				f"Rank {mp.current_process().name}: epoch {epoch+1}: w = {w[0][0].item():.3f}, loss = {l:.3f}"
			) 


# Main function 
if __name__ == "__main__": 
	# Set the number of processes and define the input and output data 
	num_processes = mp.cpu_count()  # Get the number of CPUs without limiting
	X = torch.tensor([[1], [2], [3], [4]], dtype=torch.float32) 
	Y = torch.tensor([[2], [4], [6], [8]], dtype=torch.float32) 
	n_samples, n_features = X.shape 

	# Print the number of samples and features 
	print(f"#samples: {n_samples}, #features: {n_features}") 

	# Define the test input and the model input/output sizes 
	X_test = torch.tensor([5], dtype=torch.float32) 
	input_size = n_features 
	output_size = n_features 

	# Define the linear model and print its prediction on the test input before training 
	model = nn.Linear(input_size, output_size) 
	print(f"Prediction before training: f(5) = {model(X_test).item():.3f}") 

	# Share the model's memory to allow it to be accessed by multiple processes 
	model.share_memory() 

	# Create a list of processes and start each process with the train function 
	processes = [] 
	for rank in range(num_processes): 
		p = mp.Process( 
			target=train, 
			args=( 
				model, 
				X, 
				Y, 
			), 
			name=f"Process-{rank}", 
		) 
		p.start() 
		processes.append(p) 
		print(f"Started {p.name}") 

	# Wait for all processes to finish 
	for p in processes: 
		p.join() 
		print(f"Finished {p.name}") 

	# Print the model's prediction on the test input after training 
	print(f"Prediction after training: f(5) = {model(X_test).item():.3f}") 
