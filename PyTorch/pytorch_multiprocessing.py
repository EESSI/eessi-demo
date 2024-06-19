import torch
import torch.multiprocessing as mp
import torch.nn as nn
import torch.optim as optim
import logging
import random

SIZE = 500
N = 10  # Number of forward passes

# Initialize logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

class SimpleNet(nn.Module):
    def __init__(self):
        super(SimpleNet, self).__init__()
        self.fc1 = nn.Linear(SIZE, 100)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(100, 10)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

def worker(rank, barrier):
    logging.info(f"Worker {rank} started")

    try:
        # Synchronize all workers
        barrier.wait()

        # Set a unique seed for each worker
        seed = torch.initial_seed() + rank
        torch.manual_seed(seed)
        random.seed(seed)

        # Create a simple neural network
        net = SimpleNet()

        # Create a random input tensor and a target tensor
        input_tensor = torch.rand((SIZE, SIZE))
        target_tensor = torch.randint(0, 10, (SIZE,))

        # Define a loss function and an optimizer
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.SGD(net.parameters(), lr=0.01)

        for _ in range(N):
            # Perform forward pass
            output = net(input_tensor)

            # Compute the loss
            loss = criterion(output, target_tensor)

            # Perform backward pass
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            logging.info(f"Worker {rank} - Loss: {loss.item()}")

        logging.info(f"Worker {rank} finished all {N} forward passes.")

    except Exception as e:
        logging.error(f"Worker {rank} failed with error: {e}")

def test():
    num_workers = mp.cpu_count()  # Get the number of CPUs without limiting
    logging.info(f"Running test on {num_workers} CPUs")

    # Create a barrier to synchronize workers
    barrier = mp.Barrier(num_workers)

    # Create a process for each CPU
    processes = []
    for rank in range(num_workers):
        p = mp.Process(target=worker, args=(rank, barrier))
        p.start()
        processes.append(p)

    # Wait for all processes to finish
    for p in processes:
        p.join()

if __name__ == "__main__":
    test()

