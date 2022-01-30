# Load in libraries
import os, sys, time, atexit, warnings, logging
from shutil import ExecError
import torch

# Setup logging
logging.basicConfig(stream=sys.stdout, 
                    format='%(asctime)s %(message)s',
                    level = logging.INFO)

# Exit handler
def exit_handler():
    print ('Exiting application')

# Run only as main file
if __name__ =="__main__":
    # Collect environmental variables
    logging.info ("*** Parsing environmental variables ***")
    app_input_dir = os.environ.get('app_input_dir', './input')
    app_output_dir = os.environ.get('app_output_dir', './output')
    app_loop_sleep = float(os.environ.get('app_loop_sleep', 1))
    model_dir_or_repo = os.environ.get('model_dir_or_repo', 'ultralytics/yolov5')
    model_name = os.environ.get('model_name', 'yolov5s')

    # Print out the inputs of the system 
    logging.info ("*** Starting main loop with setup as ***")
    logging.info ("Input directory:\t\t%s", app_input_dir) 
    logging.info ("Output directory:\t\t%s", app_output_dir) 
    logging.info ("Sleep time:\t\t\t%s", app_loop_sleep) 
    logging.info ("Model directory or repo:\t%s", model_dir_or_repo) 
    logging.info ("Model name:\t\t\t%s", model_name) 

    # Setup exit handler
    atexit.register(exit_handler)

    # Ignore warnings 
    warnings.filterwarnings("ignore")

    try:
        # Load in desired model
        logging.info ("*** Loading Models ***")
        model = torch.hub.load(model_dir_or_repo, model_name)
    except Exception as err:
        raise SystemExit("Failed to load in models from desired repository: ", err)
    else:
        # Looging
        logging.info ("*** Application started ***")

        # Continuously monitor the input dir for input files
        while True:
            try:
                # Check if the input dir has any new files
                if (len(os.listdir(app_input_dir)) > 0) : 
                    # Loop each file in the dir and run inference on images 
                    for filename in os.listdir(app_input_dir):
                        # Attempt to run inference on the file
                        try:
                            # Logging
                            logging.info ("Processing file: %s", filename)

                            # Check for valid image inputs
                            if (filename.lower().endswith(('.png', '.jpg', '.jpeg', '.tiff', '.bmp'))):
                                # Run inference
                                results = model(app_input_dir + "/" + filename)

                                # Print results to output
                                results.print()

                                # Save image to output dir
                                results.save(app_output_dir)

                                # Save results to JSON
                                results.pandas().xyxy[0].to_json(app_output_dir + "/" + os.path.splitext(filename)[0] + '.json', orient='records')
                            else: 
                                logging.warn("%s was not an image, deleting it", filename) 
                        except Exception as err:
                            raise RuntimeError("Failed to run inference on file: ", err)
                        finally:
                            try:
                                # Remove file from input folder when done
                                logging.info ("Removing file: %s", filename)
                                os.remove(app_input_dir + "/" + filename)
                            except Exception as err:
                                raise RuntimeError("Failed to delete filename: ", err)

                # Sleep to allow application to rest
                time.sleep(app_loop_sleep)
            except Exception as err:
                logging.warn('Main loop encounted error:', err)

else :
    raise ExecError('Yolov5 watcher module is intended to be run as __main__')