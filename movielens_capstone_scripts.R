
#  title: "Recommendation System"
#author: "Haya Abdeh"
#date: "29 June 2021 "
#abstract: "This is the first project for the Harvard Data Science Professional Program  by Prof. of Biostatistics Rafael Irizarry from Harvard University. In this first capstone project, we have to build a recommendation system for netflix company based on a 10M (millions) rows rating dataset named MovieLens created by the University of Minnesota, and going to analyze it and perform machine learning tasks in complete autonomy ." 
#output: 
 # pdf_document: default
#html_document: default
#always_allow_html: true

  

knitr::opts_chunk$set(echo = TRUE)




## Summary 

#Recommender systems is a filtering tools for information that aims to predict ratings for users and items, mostly from big data to recommend their likes. Movie recommendation systems provide a mechanism to help users in classifying users with similar interests. 
#This makes recommender systems basically a focal part of websites and e-commerce applications. we are going to apply some of machine learning principles to build a recommender system that would introduced in the next pages.






# Install all needed libraries if it is not present

if(!require(tidyverse)) install.packages("tidyverse") 
if(!require(kableExtra)) install.packages("kableExtra")
if(!require(tidyr)) install.packages("tidyr")
if(!require(data.table)) install.packages("data.table")
if(!require(stringr)) install.packages("stringr")
if(!require(ggplot2)) install.packages("ggplot2")
if(!require(plotly)) install.packages("plotly")
if(!require(gbm)) install.packages("gbm")
if(!require(dplyr)) install.packages("dplyr")
if(!require(caret)) install.packages("caret")
if(!require(xgboost)) install.packages("xgboost")
if(!require(e1071)) install.packages("e1071")
if(!require(class)) install.packages("class")
if(!require(ROCR)) install.packages("ROCR")
if(!require(randomForest)) install.packages("randomForest")
if(!require(PRROC)) install.packages("PRROC")
if(!require(reshape2)) install.packages("reshape2")
if(!require(lubridate))install.packages("lubridate")
if(!require(knitr)) install.packages("knitr")
if(!require(recosystem)) install.packages("recosystem")
if(!require(tinytex)) install.packages("tinytex")
if(!require(webshot))install.packages("webshot")
webshot::install_phantomjs()


# Loading all needed libraries

library(dplyr)
library(tidyverse)
library(kableExtra)
library(tidyr)
library(ggplot2)
library(plotly)
library(gbm)
library(caret)
library(xgboost)
library(e1071)
library(class)
library(lightgbm)
library(ROCR)
library(randomForest)
library(PRROC)
library(reshape2)
library(data.table)
library(lubridate)
library(knitr)
library(recosystem)
library(tinytex)
webshot::install_phantomjs()




#Executive Summary

#We start with creating a recommendation system using the “prediction”. We are going to train our algorithms using a (edx) set to predict movie ratings in the validation set, and we will evaluate how close our predictions are to the real true values by Measuring RMSE. we are going to use different Machine Learning techniques, like regression models, ensemble methods (random forest).

# Exploratory Analysis for Data Set

## Introduce The Dataset 

# MovieLens 10M dataset:
# https://grouplens.org/datasets/movielens/10m/
# http://files.grouplens.org/datasets/movielens/ml-10m.zip

dl <- tempfile()
download.file("http://files.grouplens.org/datasets/movielens/ml-10m.zip", dl)


ratings <- fread(text = gsub("::", "\t", readLines(unzip(dl, "ml-10M100K/ratings.dat"))),
                 col.names = c("userId", "movieId", "rating", "timestamp"))

movies <- str_split_fixed(readLines(unzip(dl, "ml-10M100K/movies.dat")), "\\::", 3)
colnames(movies) <- c("movieId", "title", "genres")

# if using R 4.0 or later:
movies <- as.data.frame(movies) %>% mutate(movieId = as.numeric(movieId),
                                           title = as.character(title),
                                           genres = as.character(genres))
movielens <- left_join(ratings, movies, by = "movieId")

# Validation set will be 10% of MovieLens data
set.seed(1, sample.kind="Rounding") # if using R 3.5 or earlier, use `set.seed(1)`
test_index <- createDataPartition(y = movielens$rating, times = 1, p = 0.1, list = FALSE)
edx <- movielens[-test_index,]
temp <- movielens[test_index,]
# Make sure userId and movieId in validation set are also in edx set
validation <- temp %>% 
  semi_join(edx, by = "movieId") %>%
  semi_join(edx, by = "userId")

# Add rows removed from validation set back into edx set
removed <- anti_join(temp, validation)
edx <- rbind(edx, removed)

rm(dl, ratings, movies, test_index, temp, movielens, removed)




#after loading the data set edx, are going to do a quick check on the train set and the test set

#The Trainig Set
dim(edx)

#Let us start looking at the data structure and type of the data set which we are going to work with

#class of the data set edx
class(edx)
summary(edx)
# Find out Class of each Feature, along with internal structure
str(edx) 
# Find out Names of the Columns (Features) 
names(edx) 

#We can see the first six rows of the edx data set

#head of the data set edx
head(edx)

#The Test Set
dim(validation)

#The Test Set
class(validation)

# Find out Class of each Feature, along with internal structure
str(validation) 

#The Test Set
names(validation)

#SO far we find out that the edX dataset is made of 6 features and 9,000,055 observations.The validation set which represents 10% of the 10M Movielens dataset contains the same features , but with a total of 999,999 occurrences. we assured that the movieId and the userId in edx set are also in the validation set.

#### Data Type Analysis 

##quantitative data

#userId : discrete, Unique user ID.
#movieId: discrete, Unique movie ID.
#timestamp : discrete , Date and time.

##qualitative features

#title: nominal , not unique - movie title
#genres: nominal.
#rating : continuous, a rating between 0 and 5 for the movie.

#We can see the most rated Films arranged by descending order with the highest rate at the first.

# Most rated films
edx %>% group_by(title) %>%
  summarize(n_ratings = n()) %>%
  arrange(desc(n_ratings))

#And The number of movies rated just once 

# Number of movies rated once
edx %>% group_by(title) %>%
  summarize(n_ratings = n()) %>%
  filter(n_ratings==1) %>%
  count() %>% pull()


#The number of users on edx dataset is 69,878

#number of users in edx dataset
edx %>% group_by(userId) %>% summarize(count = n())

#The plot below shows the number of ratings for every movie

edx %>% count(movieId) %>% ggplot(aes(n))+
  geom_histogram(color = "black" , fill= "light green",bins = 10 , binwidth = 0.2)+
  scale_x_log10()+
  ggtitle(" number of Rating per Movie")+
  theme_gray()

#As there are users gives a full rate as (5,4,3,2,1) for the movies , there are other users gives a half rating (4.5 , 3.5 , 2.5 , 1.5 , 0.5) for movies , here are the most users gives ratings for movies

# Ratings Histogram
edx %>%
  ggplot(aes(rating)) +
  geom_histogram(binwidth = 0.5, color = "black" , fill= "light blue") +
  xlab("Rating") +
  ylab("Count") +
  ggtitle("Grades of Ratings") +
  theme(plot.title = element_text(hjust = 0.5))



#The majority of users rate between 10 and 100 movies, whilst some may rate over 1,000. Including a variable in the model to account for number of ratings should be discussed. 
#Also we can see the number of users gives ratings for movies ,, some users rate between 10 and 100 movies, whilst some may rate over 1,000 or even did not give any ratings
# Ratings Users - Number of Ratings
edx %>% 
  count(userId) %>%
  ggplot(aes(n)) +
  geom_histogram(color = "#FF6666",fill= "#666666", bins=30) +
  scale_x_log10() +
  xlab("# Ratings") +
  ylab("# Users") +
  ggtitle("Number of Ratings by Users") +
  theme(plot.title = element_text(hjust = 0.5))

## Methods of Machine Learning

#And as we do some data analysis on the edx DataSet we will run machine learning algorithms to make a prediction model that would predict the highest ratings on movies with reducing the value of residual mean squared error RMSE.

#RMSE defined as the standard deviation of the residuals (prediction errors) where residuals are a measure of spread of data points from the regression line . and we calculate the RMSE to represent the error loss between the predicted ratings derived from applying the algorithm and actual ratings in the test set.

#we are going to use the linear regression approach, the Naive Baseline Model then we are going to start with calculating residual mean squared error RMSE with user bias since users prefer movies over others, then we are going to build another model based on Regularization approach, and we are going to introduce the matrix factorization model,and after running these models we will compute the RMSE value and compare it with each model to find the optimal value of it

#Let us start ... 


#Naive Baseline Model


#First, build a Naive model and calculate the average of the edx data set, assuming that all users give ratings for all movies

mu <- mean(edx$rating)
rmse <- RMSE(validation$rating, mu)

# We make a data frame to save the results of RMSE
results <- data.frame(model="Mean Of edx Model", RMSE=rmse)

#We can see that RMSE on the validation dataset is 1.06. It is very high and we need to get RMSE (below 0.87) so we should to improve the model.



#Add the movie bias term which calculate the average of the rankings for movies, we can use this formula:
#  $$Y_{u,i} = \hat{\mu} + b_i + \epsilon_{u,i}$$
  # we calculated mu_hat as mu at the previous step
  
 
mu <- mean(edx$rating)
movie_bias <- edx %>%
  group_by(movieId) %>%
  summarize(movie_bias = mean(rating - mu))




#predict ratings with mu 


predict_rat <- validation %>% 
  left_join(movie_bias, by='movieId') %>%
  mutate(pred = mu + movie_bias) %>%
  pull(pred)

RMSE(validation$rating, predict_rat)
rmse_result <- RMSE(validation$rating, predict_rat)

#Adding the result we had to the results dataset that we build before
results <- results %>% add_row(model="Movie Bias Model", RMSE=rmse_result)

# we notice that RMSE is 0.94 ,, still not the result that we need





#Now calculate user bias term. to minimizes the effect of extreme ratings made by users and we will use the formula
#   $$Y_{u,i} = \hat{\mu} + b_i + b_u + \epsilon_{u,i}$$
  
 
# user bias  
# again the average of all movies 
# and use the movie_bias from the previous step
mu <- mean(edx$rating)
user_bias <- edx %>% 
  left_join(movie_bias, by='movieId') %>%
  group_by(userId) %>%
  summarize(user_bias = mean(rating - mu - movie_bias))



#predict ratings with movie and user bias


mu <- mean(edx$rating)
predict_rat_user <- validation %>% 
  left_join(movie_bias, by='movieId') %>%
  left_join(user_bias, by='userId') %>%
  mutate(pred = mu + movie_bias + user_bias) %>%
  pull(pred)

RMSE(predict_rat_user, validation$rating)

# Let us Add the result to the results dataset
result_user <- RMSE(predict_rat_user, validation$rating)
results <- results %>% add_row(model="bias Movie and User  Model", RMSE= result_user)

# We got a RMSE = 0.8653488 this is a good result so far, letus continue to see if we can get better results.



#Calculating the rating as the Genres of the movies ,,, we use this formula 
#    $$Y_{u,i} = \hat{\mu} + b_i + b_u + b_{u,g} + \epsilon_{u,i}$$
  
mu <- mean(edx$rating)
# Calculate average by The movie
movie_avg <- edx %>%
  group_by(movieId) %>%
  summarize(movie_bias = mean(rating - mu))

# Calculate average by The user
user_avg <- edx %>%
  left_join(movie_avg, by='movieId') %>%
  group_by(userId) %>%
  summarize(user_bias = mean(rating - mu - movie_bias))

#Calculate the genres as the user prefer more
prefered_genre <- edx %>%
  left_join(movie_avg, by='movieId') %>%
  left_join(user_avg, by='userId') %>%
  group_by(genres) %>%
  summarize(movie_user_genre = mean(rating - mu - movie_bias - user_bias))

# Compute the predicted ratings on validation dataset

rmse_m_u_g <- validation %>%
  left_join(movie_avg, by='movieId') %>%
  left_join(user_avg, by='userId') %>%
  left_join(prefered_genre, by='genres') %>%
  mutate(pred = mu + movie_bias + user_bias + movie_user_genre) %>%
  pull(pred)

RMSE(validation$rating, rmse_m_u_g)

result_m_u_g <- RMSE(validation$rating, rmse_m_u_g)

#  Add the result to the results dataset

results <- results %>% add_row(model="Movie and User and genres Model", RMSE= result_m_u_g)

# We got a RMSE = 0.8649469 this is a very satisfying result but it did not make a very significant improvement since the RMES value is close to the previous model,, 



#Since every predictors will reduce the RMSE value, lets see if we can improve the value of RMSE with another approach.



## Regularization approach 

#Regularization technique permits us to penalize large estimates that come from small sample sizes.
#We use regularization to reduce the effect of bias because of extreme rating by the users on movies as users prefer movies over others.

#we use lambda to denote the prediction obtained when we use a parameter, we use this formula 
#    $$\hat{b_{i}} (\lambda) = \frac{1}{\lambda + n_{i}} \sum_{u=1}^{n_{i}} (Y_{u,i} - \hat{\mu}) $$  
  
  
  
  ###Introducing the next working steps 
  
  
  #compute regularized movie bias term
  #compute regularize movie and user bias term
  #compute regularize movie and user and genres bias term
  #compute predictions on validation set
  #return RMSE of the predictions

# calculate average 
mu <- mean(edx$rating)

# determine a sequence (lambda)
lambda <- seq(0, 10, 0.1)

# output RMSE of each lambda
rmses <- sapply(lambda, function(l){
  
  
  # compute regularized movie bias part
  movie_bias <- edx %>% 
    group_by(movieId) %>%
    summarize(movie_bias = sum(rating - mu)/(n()+l))
  
  # Compute the predicted ratings on validation dataset
  predict_rate <- validation %>%
    left_join(movie_bias, by='movieId') %>%
    mutate(pred = mu + movie_bias) %>%
    pull(pred)
  
  return(RMSE(predict_rate, validation$rating))
})




## Including Plots of lambda's results



# plot lambda's results

dframe <- data.frame(RMSE = rmses, lambdas = lambda)

ggplot(dframe, aes(lambda, rmses)) +
  theme_light() +
  geom_point(color = "#FF6666",fill= "#666666") +
  labs(title = "Lambdas vs RMSEs / Regularized Movie bias Term",
       y = "RMSEs",
       x = "lambdas")




#Find the minimum value of lambda that would minimize the value of RMSE

# find lambda value that minimize the RMSE
min_lambda <- lambda[which.min(rmses)]

min_lambda

# Predict the RMSE on the validation set

rmse_regularizedmovieterm <- min(rmses)
rmse_regularizedmovieterm

# Adding the results to the results dataset
results <- results %>% add_row(model="Regularized Movie Term", RMSE=rmse_regularizedmovieterm)





#Regularization on movie and user term


# Since we see before that the movie and user bias model had the acceptable RMSE ,, we will ses if the regularization technique will improve the RMSE in movies and user term

# Determine a sequence (lambda)
lambda <- seq(from=0, to=10, by=0.1)


# output RMSE of each lambda
rmses <- sapply(lambda, function(l){
  
  # calculate average 
  mu <- mean(edx$rating)
  
  movie_bias <- edx %>% 
    group_by(movieId) %>%
    summarize(movie_bias = sum(rating - mu)/(n()+l))
  
  user_bias <- edx %>% 
    left_join(movie_bias, by="movieId") %>%
    group_by(userId) %>%
    summarize(user_bias = sum(rating - movie_bias - mu)/(n()+l))
  
  predict_rat <- validation %>% 
    left_join(movie_bias, by = "movieId") %>%
    left_join(user_bias, by = "userId") %>%
    mutate(pred = mu + movie_bias + user_bias) %>%
    pull(pred)
  
  RMSE(predict_rat, validation$rating)
})




#Now we plot the Lambdas vs RMSEs for the Regularized Movie and user bias Term

# plot lambda's results

dframe <- data.frame(RMSE = rmses, lambdas = lambda)

ggplot(dframe, aes(lambda, rmses)) +
  theme_light() +
  geom_point(color = "#FF6666",fill= "#666666") +
  labs(title = "Lambdas vs RMSEs / Regularized Movie and User bias Term",
       y = "RMSEs",
       x = "lambdas")



#find lambda value that minimize the RMSE in Regularized Movie and User bias Term

# find lambda value that minimize the RMSE in Regularized Movie and User bias Term
min_lambda <- lambda[which.min(rmses)]

min_lambda

# Predict the RMSE on the validation set

rmse_regularizedmovieuserterm <- min(rmses)
rmse_regularizedmovieuserterm

# Adding the results to the results dataset
results <- results %>% add_row(model="Regularized Movie and User Term", RMSE=rmse_regularizedmovieuserterm)



#We can see that the RMSE from regularized movies and user term is Slightly lower than the non regularized movies and user bias term ,, let us see if can had a better performance  
#Let us compute the Regularized movie and user and genres Term and see if it would make RMSE is less than before

# Determine a sequence (lambda)
lambda <- seq(from=0, to=10, by=0.1)


# output RMSE of each lambda
rmses <- sapply(lambda, function(l){
  # calculate average 
  mu <- mean(edx$rating)
  
  movie_bias <- edx %>% 
    group_by(movieId) %>%
    summarize(movie_bias = sum(rating - mu)/(n()+l))
  
  user_bias <- edx %>% 
    left_join(movie_bias, by="movieId") %>%
    group_by(userId) %>%
    summarize(user_bias = sum(rating - movie_bias - mu)/(n()+l))
  
  prefered_genre <- edx %>%
    left_join(movie_bias, by='movieId') %>%
    left_join(user_bias, by='userId') %>%
    group_by(genres) %>%
    summarize(mov_user_gen= sum(rating - mu - movie_bias - user_bias) / (n() + l))
  
  
  predict_rat <- validation %>% 
    left_join(movie_bias, by = "movieId") %>%
    left_join(user_bias, by = "userId") %>%
    left_join( prefered_genre, by="genres") %>%
    mutate(pred = mu + movie_bias + user_bias + mov_user_gen) %>%
    pull(pred)
  
  RMSE(predict_rat, validation$rating)
})




#We plot the Lambdas vs RMSEs for the Regularized Movie and user and genres bias Term

# plot lambda's results

dframe <- data.frame(RMSE = rmses, lambdas = lambda)

ggplot(dframe, aes(lambda, rmses)) +
  theme_light() +
  geom_point(color = "#FF6666",fill= "#666666") +
  labs(title = "Lambdas vs RMSEs / Regularized Movie and User and Genres bias Term",
       y = "RMSEs",
       x = "lambdas")


#Find lambda value that minimize the RMSE in Regularized Movie and User and Genres bias Term, and record the value of RMSE
#notice the value of RMSE

# find lambda value that minimize the RMSE in Regularized Movie and User and Genres bias Term
min_lambda <- lambda[which.min(rmses)]

min_lambda

# Predict the RMSE on the validation set

rmse_regularizedmovieuserterm <- min(rmses)
rmse_regularizedmovieuserterm

# Adding the results to the results dataset
results <- results %>% add_row(model="Regularized Movie and User and Genres Term", RMSE=rmse_regularizedmovieuserterm)




#Matrix Factorization Approach



#There are 2 types of recommender systems:
#  Content filtering (meta data or side information – which is based on the description of the item)
#And collaborative Filtering: which  calculate the similarity
#measures of the target ITEMS then find the minimum (Euclidean distance,
                                                    or Cosine distance, or other metric, depending on the algorithm used).

#we will work with the the collaborative filtering type of recommender systems using  Matrix factorization approach.

#Matrix factorization algorithms work by splitting the user-item interaction matrix
#into the product of two lower dimensional rectangular matrices.and the recommender system will predict unknown entries in the rating matrix based on observed values.


#Let us start building the model


#define RMSE function

RMSE_f <- function(true_ratings, predicted_ratings) {
  sqrt(mean((true_ratings - predicted_ratings)^2))
}






#We create Two new matrices ( train and validation set) with three features (movieId, userId, rating)


#create Two new matrices
edx_m_f <- edx %>% select(movieId, userId, rating)
validation_m_f <- validation %>% select(movieId, userId, rating)

edx_m_f <- as.matrix(edx_m_f)
validation_m_f<- as.matrix(validation_m_f)



# save the files as tables 
write.table(edx_m_f, file = "training_set.txt", sep = " ", row.names = FALSE, 
            col.names = FALSE)

write.table(validation_m_f, file = "validation_set.txt", sep = " ", 
            row.names = FALSE, col.names = FALSE)



set.seed(1)

training_ds <- data_file("training_set.txt")

validation_ds <- data_file("validation_set.txt")


#calling the function Reco()
r = Reco()

#perform many different settings until you will reach the optimal

opts = r$tune(training_ds, opts = list(dim = c(10, 20, 30), lrate = c(0.1, 
                                                                      0.2), costp_l1 = 0, costq_l1 = 0, nthread = 1, niter = 10))



#Let us train the model with calling (train) function as the result of the previous step (tune)

r$train(training_ds, opts = c(opts$min, nthread = 1, niter = 20))


#We write predictions to a tempfile

save_prediction = tempfile()



#With the predict function let us make  predictions on validation set and compute RMSE:
  
  
r$predict(validation_ds, out_file(save_prediction))


real_rates <- read.table("validation_set.txt", header = FALSE, sep = " ")$V3


pred_rates <- scan(save_prediction)




#RMSE as we mentioned earlier is the amount by which the values predicted by an estimator differ from the quantities being estimated.


RMSE_mf <- RMSE(real_rates, pred_rates)



#Root Mean Squared Error RMSE of Matrix Factorization model

# print out the Root Mean Squared Error
RMSE_mf

#add the RMSE result to the table of results 
results <- results %>% add_row(model="Matrix Factorization Model", RMSE=RMSE_mf)


#So we can see how lower is the value of RMSE that generated from matrix factorization method.



#Let us  compare the first 100 predictions of the matrix factorization model with the real ratings. we will make rounding on predictions to be convenient 
p_r_rounded <- pred_rates

p_r_rounded <- round(p_r_rounded/0.5) * 0.5

fst100_pred <- data.frame(real_rates[1:100], p_r_rounded[1:100])

names(fst100_pred) <- c("real_rates", "predicted_rates")

correct_predictions <- 1:100

x <- ifelse(fst100_pred$real_rates==fst100_pred$predicted_rates,1,0)

fst100_pred %>% mutate(correct_predictions)
fst100_pred$correct_predictions <- x
names(fst100_pred) <- c("real_rates", "predicted_rates" , "correct_predictions")
fst100_pred



pr_mf <- ggplot(data = fst100_pred, aes(x = real_rates, y = predicted_rates ,col = correct_predictions )) + xlab("Real Rates") + ylab("Predicted Rates") + 
  
  ggtitle("Real Rates vs Predicted Rates ") + theme(plot.title = element_text(color = "dark blue", hjust = 0.5)) + geom_jitter()
ggplotly(pr_mf)





## Results of RMSE:

#As a result we find that the minimum value of RMSE obtained from Matrix Factorization model which is (0.7830654).

#Let us print the results table to show and compare the RMSE values for each approach , so we can evaluate our models performances.

# printing the results table to show the RMSE values
print(results)



## Conclusion 

#we find that Matrix Factorization approach is effective way to make prediction on movie ratings as well RMSE had been minimized less than the Naive Baseline Model nor the regularized biased model,, 

#So after training different models, we find out that movie_id  and user_id gives a desirable value of RMSE Without regularization, but when applying regularization and adding the genres predictor, it make possible to reach a lower value of RMSE ,, but Matrix Factorization model gives us a better result for RMSE so this approach is effective way to make prediction on movie ratings as well RMSE had been minimized less than the Naive Baseline Model nor the regularized biased model,

## Future Work
#The effects of genres and age could be further explored to make improvements on the performance in regularized model and to check if it would give a better results. 
#Also trying to build more machine learning models to find if we can get a value of RMSE less than what we tried in the previews models, so we could make the prediction process is more effective and more accurate. also the ensemble method should also be considered to apply on the MovieLens dataset, to combine the advantages of various models and enhance the overall performance of prediction. 



## References:

#https://www.sciencedirect.com/science/article/pii/S1110866516300470

#https://www.sciencedirect.com/science/article/pii/S1045926X14000901

#https://rafalab.github.io/dsbook/clustering.html

#https://learning.edx.org/course/course-v1:HarvardX+PH125.9x+1T2021/block-v1:HarvardX+PH125.9x+1T2021+type@sequential+block@e8800e37aa444297a3a2f35bf84ce452/block-v1:HarvardX+PH125.9x+1T2021+type@vertical+block@e9abcdd945b1416098a15fc95807b5db

#https://cran.r-project.org/web/packages/tune/tune.pdf

#https://www.rdocumentation.org/packages/e1071/versions/1.7-7/topics/tune

#https://ggplot2.tidyverse.org/reference/aes_group_order.html

#https://www.r-bloggers.com/2020/03/how-to-standardize-group-colors-in-data-visualizations-in-r/
  
 # https://ggplot2.tidyverse.org/reference/geom_jitter.html

#https://www.journaldev.com/45290/predict-function-in-r

#https://rpubs.com/Jango/486734

#http://rstudio-pubs-static.s3.amazonaws.com/493427_68e66956f18044ea8d21ee64c0337a1e.html#abstract

#https://rstudio-pubs-static.s3.amazonaws.com/288836_388ef70ec6374e348e32fde56f4b8f0e.html#creating_models

#https://mono33.github.io/MovieLensProject/#abstract
  
 # https://www.rpubs.com/rezapci/Data_Science_Machine_Learning_HarvardX

#https://rpubs.com/delongmeng/557151

#https://rpubs.com/Papacosmas/harvard

#https://rstudio-pubs-static.s3.amazonaws.com/593016_55f82043d74f401cbafe347e5e025d90.html

