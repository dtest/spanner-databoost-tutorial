# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https:#www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Query Spanner without Data Boost"""

import argparse, time
from datetime import datetime
import concurrent.futures
from google.cloud import spanner

def run_batch_query(client):
    """Runs an example batch query."""
    # Create the batch transaction and generate partitions

    query="""SELECT users.userUUID, SHA256(users.email) as hashed_email, COUNT(*) num_topics,
                    (SELECT MAX(created) FROM topics WHERE userUUID=users.userUUID) as last_posted
            FROM users
            INNER JOIN topics USING(userUUID)
            GROUP BY users.userUUID, users.email"""

    snapshot = client.batch_snapshot()
    partitions = snapshot.generate_query_batches(
        sql=query,
        data_boost_enabled=False,
    )

    # Create a pool of workers for the tasks
    start = time.time()

    print("Started request at {}".format(datetime.fromtimestamp(start)))
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [executor.submit(process, snapshot, p) for p in partitions]

        for future in concurrent.futures.as_completed(futures, timeout=3600):
            finish, row_ct = future.result()
            elapsed = finish - start
            print("Completed {} rows in {} seconds".format(row_ct, elapsed))

    # Clean up
    snapshot.close()


def process(snapshot, partition):
    """Processes the requests of a query in an separate process."""
    print("Started processing partition.")
    row_ct = 0
    for row in snapshot.process_query_batch(partition):
        print("UserUUID: {}, Hashed Email: {}, Num Topics: {}, Last Posted: {}".format(*row))
        row_ct += 1
    return time.time(), row_ct


parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
)
parser.add_argument("-instance_id", help="Your Spanner instance ID.", required=True)
parser.add_argument("-database_id", help="Your Spanner database ID.", required=True)

args = parser.parse_args()


spanner_client = spanner.Client()
instance = spanner_client.instance(args.instance_id)
database = instance.database(args.database_id)

run_batch_query(database)
